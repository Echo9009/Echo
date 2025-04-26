mod client_manager;
mod ip_allocator;
mod user_db;

use anyhow::Result;
use clap::Parser;
use common::crypto;
use common::config::ServerConfig;
use quinn::{Endpoint, ServerConfig as QuinnServerConfig};
use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::fs;
use tracing::{error, info};
use tracing_subscriber::EnvFilter;

use client_manager::ClientManager;
use ip_allocator::IpAllocator;
use user_db::UserDatabase;

#[derive(Parser, Debug)]
#[clap(author, version, about)]
struct Args {
    #[clap(short, long, default_value = "config.json")]
    config: PathBuf,

    #[clap(short, long)]
    generate_cert: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    if args.generate_cert {
        generate_certificate().await?;
        return Ok(());
    }

    let config = ServerConfig::load(args.config.to_str().unwrap())?;

    // Initialize logging
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| {
        EnvFilter::new(config.log_level.clone())
    });
    
    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .init();

    info!("Starting QUIC VPN Server v{}", env!("CARGO_PKG_VERSION"));

    // Load certificates
    let cert = fs::read(&config.cert_path).await?;
    let key = fs::read(&config.key_path).await?;
    
    // Create TLS configuration
    let server_crypto_config = crypto::load_server_config(&cert, &key)?;
    
    // Setup QUIC configuration
    let mut server_config = QuinnServerConfig::with_crypto(Arc::new(server_crypto_config));
    
    // Configure with gaming optimizations
    server_config.transport = Arc::new({
        let mut transport_config = quinn::TransportConfig::default();
        // Optimize for gaming - reduce latency
        transport_config.max_idle_timeout(Some(std::time::Duration::from_secs(30).try_into()?));
        transport_config.keep_alive_interval(Some(std::time::Duration::from_secs(5)));
        
        if config.gaming_optimization {
            // Higher priority for real-time data
            transport_config.datagram_receive_buffer_size(None);
            // Faster recovery from packet loss
            transport_config.initial_rtt(std::time::Duration::from_millis(100));
        }
        
        transport_config
    });
    
    // Create user database
    let user_db = UserDatabase::load(&config.user_db_path).await?;
    
    // Create IP allocator
    let ip_allocator = IpAllocator::new(config.vpn_network, config.vpn_netmask, config.max_clients);
    
    // Create client manager
    let client_manager = ClientManager::new(
        config.clone(),
        user_db,
        ip_allocator,
    );
    
    // Create and setup the endpoint
    let endpoint = Endpoint::server(server_config, config.listen_addr)?;
    
    info!("Listening on {}", config.listen_addr);
    
    // Accept new connections
    loop {
        match endpoint.accept().await {
            Some(conn) => {
                let client_manager = client_manager.clone();
                
                tokio::spawn(async move {
                    match conn.await {
                        Ok(connection) => {
                            let remote_addr = connection.remote_address();
                            info!("Connection from {}", remote_addr);
                            
                            if let Err(e) = client_manager.handle_connection(connection).await {
                                error!("Error handling client connection from {}: {}", remote_addr, e);
                            }
                        }
                        Err(e) => {
                            error!("Connection failed: {}", e);
                        }
                    }
                });
            }
            None => break,
        }
    }

    Ok(())
}

async fn generate_certificate() -> Result<()> {
    let hostname = "quicvpn.server";
    println!("Generating self-signed certificate for hostname: {}", hostname);
    
    let (cert, key) = crypto::generate_self_signed_cert(hostname)?;
    
    fs::write("server.crt", cert).await?;
    fs::write("server.key", key).await?;
    
    println!("Certificate and key have been saved to server.crt and server.key");
    
    // Generate default config file
    let config = ServerConfig {
        listen_addr: "0.0.0.0:4433".parse()?,
        cert_path: "server.crt".into(),
        key_path: "server.key".into(),
        vpn_network: "10.10.0.0".parse()?,
        vpn_netmask: "255.255.255.0".parse()?,
        mtu: 1400,
        log_level: "info".to_string(),
        user_db_path: "users.json".into(),
        max_clients: 100,
        gaming_optimization: true,
    };
    
    config.save("config.json")?;
    println!("Default config file has been saved to config.json");
    
    // Create a default user database
    let mut user_db = user_db::UserDatabase::new();
    user_db.add_user("admin".to_string(), "password".to_string());
    
    user_db.save("users.json").await?;
    println!("Default user database has been saved to users.json with admin:password");
    
    Ok(())
} 