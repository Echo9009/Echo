use anyhow::Result;
use common::protocol::Message;
use common::tun_device::TunDevice;
use common::config::ServerConfig;
use dashmap::DashMap;
use quinn::{Connection, RecvStream, SendStream};
use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::Arc;
use tokio::sync::mpsc;
use tokio::task::JoinHandle;
use tracing::{error, info, warn};

use crate::ip_allocator::IpAllocator;
use crate::user_db::UserDatabase;

#[derive(Debug)]
struct ClientInfo {
    username: String,
    assigned_ip: IpAddr,
    connection: Connection,
    task_handle: JoinHandle<()>,
}

#[derive(Clone)]
pub struct ClientManager {
    config: ServerConfig,
    user_db: UserDatabase,
    ip_allocator: IpAllocator,
    clients: Arc<DashMap<IpAddr, ClientInfo>>,
    tun_device: Arc<TunDevice>,
    packet_tx: mpsc::Sender<(Vec<u8>, IpAddr)>,
    packet_rx: Arc<mpsc::Receiver<(Vec<u8>, IpAddr)>>,
}

impl ClientManager {
    pub fn new(
        config: ServerConfig,
        user_db: UserDatabase,
        ip_allocator: IpAllocator,
    ) -> Self {
        // Create TUN device for server
        let tun_device = TunDevice::new(
            Some("quicvpn0"),
            config.vpn_network,
            config.vpn_netmask,
            config.mtu,
        ).expect("Failed to create TUN device");

        let (packet_tx, packet_rx) = mpsc::channel(1000);

        let instance = Self {
            config,
            user_db,
            ip_allocator,
            clients: Arc::new(DashMap::new()),
            tun_device: Arc::new(tun_device),
            packet_tx,
            packet_rx: Arc::new(packet_rx),
        };

        // Start packet forwarder
        instance.start_packet_forwarder();

        instance
    }

    pub async fn handle_connection(&self, connection: Connection) -> Result<()> {
        // Open bidirectional stream for control messages
        let (mut send, mut recv) = connection.open_bi().await?;

        // Receive client hello message
        let client_hello = self.receive_message(&mut recv).await?;

        match client_hello {
            Message::ClientHello { username, password, client_version } => {
                info!("Client hello from user: {}, version: {}", username, client_version);

                // Authenticate user
                if !self.user_db.authenticate(&username, &password) {
                    self.send_message(
                        &mut send,
                        &Message::Disconnect {
                            reason: "Authentication failed".to_string(),
                        },
                    ).await?;
                    
                    return Ok(());
                }

                // Allocate IP address
                let assigned_ip = if let Some(ip) = self.ip_allocator.allocate_ip() {
                    ip
                } else {
                    self.send_message(
                        &mut send,
                        &Message::Disconnect {
                            reason: "No available IP addresses".to_string(),
                        },
                    ).await?;
                    
                    return Ok(());
                };

                // Send server hello message
                self.send_message(
                    &mut send,
                    &Message::ServerHello {
                        server_version: env!("CARGO_PKG_VERSION").to_string(),
                        assigned_ip,
                        subnet_mask: self.config.vpn_netmask,
                        mtu: self.config.mtu,
                    },
                ).await?;

                // Start client handler
                let task_handle = self.start_client_handler(
                    connection.clone(),
                    username.clone(),
                    assigned_ip,
                    send,
                    recv,
                ).await?;

                // Store client info
                let client_info = ClientInfo {
                    username,
                    assigned_ip,
                    connection: connection.clone(),
                    task_handle,
                };

                self.clients.insert(assigned_ip, client_info);

                info!("Client connected: {}", assigned_ip);
            }
            _ => {
                self.send_message(
                    &mut send,
                    &Message::Disconnect {
                        reason: "Expected ClientHello".to_string(),
                    },
                ).await?;
                
                return Ok(());
            }
        }

        Ok(())
    }

    async fn send_message(&self, stream: &mut SendStream, message: &Message) -> Result<()> {
        let data = message.to_bytes()?;
        let data_len = data.len() as u32;
        
        // Write message length
        stream.write_all(&data_len.to_be_bytes()).await?;
        
        // Write message data
        stream.write_all(&data).await?;
        
        Ok(())
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

    fn start_packet_forwarder(&self) {
        let tun_device = self.tun_device.clone();
        let packet_tx = self.packet_tx.clone();
        let clients = self.clients.clone();
        
        // Spawn task to read from TUN and forward to clients
        tokio::spawn(async move {
            let (tun_packet_tx, mut tun_packet_rx) = mpsc::channel(1000);
            
            // Start reading from TUN device
            let _ = tun_device.start_reading(tun_packet_tx);
            
            // Process packets from TUN device
            while let Some(packet) = tun_packet_rx.recv().await {
                // Extract destination IP from packet
                if packet.len() > 20 {  // IPv4 header is at least 20 bytes
                    let version = (packet[0] >> 4) & 0xF;
                    
                    if version == 4 {  // IPv4
                        let dst_ip = IpAddr::V4(std::net::Ipv4Addr::new(
                            packet[16], packet[17], packet[18], packet[19]
                        ));
                        
                        // Forward packet to the appropriate client
                        if clients.contains_key(&dst_ip) {
                            if let Err(e) = packet_tx.send((packet, dst_ip)).await {
                                error!("Failed to forward packet to client {}: {}", dst_ip, e);
                            }
                        }
                    }
                }
            }
        });
    }

    async fn start_client_handler(
        &self,
        connection: Connection,
        username: String,
        client_ip: IpAddr,
        send: SendStream,
        recv: RecvStream,
    ) -> Result<JoinHandle<()>> {
        let tun_device = self.tun_device.clone();
        let packet_tx = self.packet_tx.clone();
        let mut packet_rx = self.packet_rx.clone();
        let clients = self.clients.clone();
        
        let handle = tokio::spawn(async move {
            // Create bistream for client communication
            let (mut send, mut recv) = (send, recv);
            
            // Keep track of client streams
            let mut client_streams = HashMap::new();
            client_streams.insert(0, (send, recv));
            
            // Create channels for packet exchange
            let (client_packet_tx, mut client_packet_rx) = mpsc::channel(1000);
            
            // Task to forward packets to the client
            let forward_task = tokio::spawn(async move {
                while let Some((packet, dst_ip)) = packet_rx.recv().await {
                    if dst_ip == client_ip {
                        if let Some((ref mut send, _)) = client_streams.get_mut(&0) {
                            let msg = Message::PacketData(packet);
                            let data = msg.to_bytes().unwrap();
                            let data_len = data.len() as u32;
                            
                            if let Err(e) = send.write_all(&data_len.to_be_bytes()).await {
                                error!("Failed to send packet length to client {}: {}", client_ip, e);
                                break;
                            }
                            
                            if let Err(e) = send.write_all(&data).await {
                                error!("Failed to send packet to client {}: {}", client_ip, e);
                                break;
                            }
                        }
                    }
                }
            });
            
            // Task to receive packets from the client
            let receive_task = tokio::spawn(async move {
                while let Some((_, ref mut recv)) = client_streams.get_mut(&0) {
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
                                            if let Err(e) = tun_device.write_packet(&packet).await {
                                                error!("Failed to write packet to TUN: {}", e);
                                            }
                                        }
                                        Ok(Message::KeepAlive) => {
                                            // Handle keep-alive message
                                        }
                                        Ok(Message::Disconnect { reason }) => {
                                            info!("Client {} requested disconnect: {}", client_ip, reason);
                                            break;
                                        }
                                        Ok(Message::GameOptimizationInfo { game_type, latency_priority }) => {
                                            info!(
                                                "Client {} set game optimization: type={}, latency_priority={}",
                                                client_ip, game_type, latency_priority
                                            );
                                        }
                                        Ok(msg) => {
                                            warn!("Unexpected message from client {}: {:?}", client_ip, msg);
                                        }
                                        Err(e) => {
                                            error!("Failed to parse message from client {}: {}", client_ip, e);
                                        }
                                    }
                                }
                                Err(e) => {
                                    error!("Failed to read message data from client {}: {}", client_ip, e);
                                    break;
                                }
                            }
                        }
                        Err(e) => {
                            error!("Failed to read message length from client {}: {}", client_ip, e);
                            break;
                        }
                    }
                }
                
                // Client disconnected
                info!("Client {} disconnected", client_ip);
                clients.remove(&client_ip);
            });
            
            // Wait for any task to complete
            tokio::select! {
                _ = forward_task => {},
                _ = receive_task => {},
            }
        });
        
        Ok(handle)
    }
} 