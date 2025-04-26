use anyhow::Result;
use common::config::ClientConfig;
use common::crypto;
use common::protocol::Message;
use common::tun_device::TunDevice;
use quinn::{ClientConfig as QuinnClientConfig, Connection, Endpoint, RecvStream, SendStream};
use std::net::IpAddr;
use std::sync::{Arc, Mutex};
use tokio::fs;
use tokio::sync::{mpsc, oneshot};
use tokio::time::{self, Duration};
use tracing::{debug, error, info, warn};

pub struct VpnClient {
    config: ClientConfig,
    connection: Option<Connection>,
    tun_device: Option<Arc<TunDevice>>,
    disconnect_tx: Option<oneshot::Sender<()>>,
}

impl VpnClient {
    pub fn new(config: ClientConfig) -> Self {
        Self {
            config,
            connection: None,
            tun_device: None,
            disconnect_tx: None,
        }
    }

    pub async fn connect(&mut self) -> Result<()> {
        // Configure QUIC client
        let client_crypto = self.setup_client_crypto().await?;
        let mut client_config = QuinnClientConfig::new(Arc::new(client_crypto));
        
        // Configure transport for gaming optimizations
        client_config.transport = Arc::new({
            let mut transport_config = quinn::TransportConfig::default();
            
            // Optimize for gaming - reduce latency
            transport_config.max_idle_timeout(Some(std::time::Duration::from_secs(30).try_into()?));
            transport_config.keep_alive_interval(Some(std::time::Duration::from_secs(5)));
            
            if self.config.gaming_optimization {
                // Higher priority for real-time data
                transport_config.datagram_receive_buffer_size(None);
                // Faster recovery from packet loss
                transport_config.initial_rtt(std::time::Duration::from_millis(100));
            }
            
            transport_config
        });
        
        // Create endpoint
        let endpoint = Endpoint::client("0.0.0.0:0".parse()?)?;
        endpoint.set_default_client_config(client_config);
        
        // Connect to server
        let connection = endpoint
            .connect(self.config.server_addr, &self.config.server_hostname)?
            .await?;
        
        info!("Connected to server: {}", self.config.server_addr);
        
        // Open control stream
        let (mut send, mut recv) = connection.open_bi().await?;
        
        // Send client hello
        self.send_message(
            &mut send,
            &Message::ClientHello {
                username: self.config.username.clone(),
                password: self.config.password.clone(),
                client_version: env!("CARGO_PKG_VERSION").to_string(),
            },
        ).await?;
        
        // Receive server hello
        let server_hello = self.receive_message(&mut recv).await?;
        
        match server_hello {
            Message::ServerHello { server_version, assigned_ip, subnet_mask, mtu } => {
                info!("Connected to server version {}", server_version);
                info!("Assigned IP: {}", assigned_ip);
                
                // Create TUN device
                let tun_device = TunDevice::new(
                    self.config.interface_name.as_deref(),
                    assigned_ip,
                    subnet_mask,
                    mtu,
                )?;
                
                // Start packet handling
                let (disconnect_tx, disconnect_rx) = oneshot::channel();
                self.start_packet_handling(
                    connection.clone(),
                    Arc::new(tun_device.clone()),
                    send,
                    recv,
                    disconnect_rx,
                ).await?;
                
                // Send game optimization information if enabled
                if self.config.gaming_optimization {
                    let (mut send, _) = connection.open_bi().await?;
                    
                    self.send_message(
                        &mut send,
                        &Message::GameOptimizationInfo {
                            game_type: self.config.game_type.clone().unwrap_or_else(|| "default".to_string()),
                            latency_priority: true,
                        },
                    ).await?;
                }
                
                // Store connection and TUN device
                self.connection = Some(connection);
                self.tun_device = Some(Arc::new(tun_device));
                self.disconnect_tx = Some(disconnect_tx);
            }
            Message::Disconnect { reason } => {
                error!("Server rejected connection: {}", reason);
                return Err(anyhow::anyhow!("Server rejected connection: {}", reason));
            }
            _ => {
                error!("Unexpected message from server");
                return Err(anyhow::anyhow!("Unexpected message from server"));
            }
        }
        
        Ok(())
    }

    pub async fn disconnect(&mut self) -> Result<()> {
        if let Some(connection) = &self.connection {
            // Send disconnect message
            if let Ok((mut send, _)) = connection.open_bi().await {
                let _ = self.send_message(
                    &mut send,
                    &Message::Disconnect {
                        reason: "Client requested disconnect".to_string(),
                    },
                ).await;
            }
            
            // Signal all tasks to stop
            if let Some(disconnect_tx) = self.disconnect_tx.take() {
                let _ = disconnect_tx.send(());
            }
            
            // Close connection
            connection.close(0u32.into(), b"Client disconnected");
            
            // Clear state
            self.connection = None;
            self.tun_device = None;
        }
        
        Ok(())
    }

    pub async fn wait_for_disconnect(&self) -> Result<()> {
        if let Some(connection) = &self.connection {
            connection.closed().await;
        }
        
        Ok(())
    }

    async fn setup_client_crypto(&self) -> Result<rustls::ClientConfig> {
        let server_cert = if let Some(cert_path) = &self.config.server_cert_path {
            // Load server certificate from file
            Some(fs::read(cert_path).await?)
        } else {
            None
        };
        
        match server_cert {
            Some(cert) => {
                // Use provided certificate
                crypto::load_client_config(&self.config.server_hostname, &cert)
            }
            None => {
                // Use default crypto settings with no certificate verification (insecure)
                let mut root_store = rustls::RootCertStore::empty();
                let mut client_config = rustls::ClientConfig::builder()
                    .with_safe_defaults()
                    .with_root_certificates(root_store)
                    .with_no_client_auth();
                
                // Allow using QUIC
                client_config.alpn_protocols = vec![b"quicvpn".to_vec()];
                
                // Disable certificate verification (for development/testing only)
                client_config.dangerous().set_certificate_verifier(Arc::new(danger::NoCertificateVerification {}));
                
                Ok(client_config)
            }
        }
    }

    async fn start_packet_handling(
        &self,
        connection: Connection,
        tun_device: Arc<TunDevice>,
        send: SendStream,
        recv: RecvStream,
        mut disconnect_rx: oneshot::Receiver<()>,
    ) -> Result<()> {
        let (tun_packet_tx, mut tun_packet_rx) = mpsc::channel(1000);
        
        // Start reading from TUN device
        let tun_read_handle = tun_device.start_reading(tun_packet_tx)?;
        
        // Start task to forward packets from TUN to server
        let connection_clone = connection.clone();
        let tun_to_server = tokio::spawn(async move {
            while let Some(packet) = tun_packet_rx.recv().await {
                match connection_clone.open_bi().await {
                    Ok((mut send, _)) => {
                        let message = Message::PacketData(packet);
                        if let Err(e) = send_message_raw(&mut send, &message).await {
                            error!("Failed to send packet to server: {}", e);
                        }
                    }
                    Err(e) => {
                        error!("Failed to open stream: {}", e);
                        break;
                    }
                }
            }
        });
        
        // Start task to forward packets from server to TUN
        let tun_device_clone = tun_device.clone();
        let mut recv = recv;
        let server_to_tun = tokio::spawn(async move {
            loop {
                // Read message length
                let mut len_buf = [0u8; 4];
                match recv.read_exact(&mut len_buf).await {
                    Ok(_) => {
                        let data_len = u32::from_be_bytes(len_buf) as usize;
                        
                        // Read message data
                        let mut data = vec![0u8; data_len];
                        match recv.read_exact(&mut data).await {
                            Ok(_) => {
                                match Message::from_bytes(&data) {
                                    Ok(Message::PacketData(packet)) => {
                                        if let Err(e) = tun_device_clone.write_packet(&packet).await {
                                            error!("Failed to write packet to TUN: {}", e);
                                        }
                                    }
                                    Ok(Message::Disconnect { reason }) => {
                                        info!("Server disconnected: {}", reason);
                                        break;
                                    }
                                    Ok(_) => {
                                        // Ignore other messages
                                    }
                                    Err(e) => {
                                        error!("Failed to parse message from server: {}", e);
                                    }
                                }
                            }
                            Err(e) => {
                                error!("Failed to read message data from server: {}", e);
                                break;
                            }
                        }
                    }
                    Err(e) => {
                        error!("Failed to read message length from server: {}", e);
                        break;
                    }
                }
            }
        });
        
        // Start keepalive task
        let connection_clone = connection.clone();
        let keepalive = tokio::spawn(async move {
            let mut interval = time::interval(Duration::from_secs(15));
            
            loop {
                interval.tick().await;
                
                match connection_clone.open_bi().await {
                    Ok((mut send, _)) => {
                        if let Err(e) = send_message_raw(&mut send, &Message::KeepAlive).await {
                            error!("Failed to send keepalive: {}", e);
                            break;
                        }
                    }
                    Err(e) => {
                        error!("Failed to open stream for keepalive: {}", e);
                        break;
                    }
                }
            }
        });
        
        // Wait for disconnect signal or tasks to complete
        tokio::spawn(async move {
            tokio::select! {
                _ = disconnect_rx => {
                    debug!("Received disconnect signal");
                }
                _ = tun_to_server => {
                    debug!("TUN to server task completed");
                }
                _ = server_to_tun => {
                    debug!("Server to TUN task completed");
                }
                _ = keepalive => {
                    debug!("Keepalive task completed");
                }
            }
            
            // Clean up
            connection.close(0u32.into(), b"Client disconnected");
        });
        
        Ok(())
    }

    async fn send_message(&self, stream: &mut SendStream, message: &Message) -> Result<()> {
        send_message_raw(stream, message).await
    }

    async fn receive_message(&self, stream: &mut RecvStream) -> Result<Message> {
        // Read message length
        let mut len_buf = [0u8; 4];
        stream.read_exact(&mut len_buf).await?;
        let data_len = u32::from_be_bytes(len_buf) as usize;
        
        // Read message data
        let mut data = vec![0u8; data_len];
        stream.read_exact(&mut data).await?;
        
        let message = Message::from_bytes(&data)?;
        Ok(message)
    }
}

async fn send_message_raw(stream: &mut SendStream, message: &Message) -> Result<()> {
    let data = message.to_bytes()?;
    let data_len = data.len() as u32;
    
    // Write message length
    stream.write_all(&data_len.to_be_bytes()).await?;
    
    // Write message data
    stream.write_all(&data).await?;
    
    Ok(())
}

// Dangerous certificate verification for development only
mod danger {
    use std::sync::Arc;
    use std::time::SystemTime;
    use rustls::{Certificate, Error, ServerName};
    use rustls::client::{ServerCertVerified, ServerCertVerifier};
    
    #[derive(Debug)]
    pub struct NoCertificateVerification {}
    
    impl ServerCertVerifier for NoCertificateVerification {
        fn verify_server_cert(
            &self,
            _end_entity: &Certificate,
            _intermediates: &[Certificate],
            _server_name: &ServerName,
            _scts: &mut dyn Iterator<Item = &[u8]>,
            _ocsp_response: &[u8],
            _now: SystemTime,
        ) -> Result<ServerCertVerified, Error> {
            Ok(ServerCertVerified::assertion())
        }
    }
} 