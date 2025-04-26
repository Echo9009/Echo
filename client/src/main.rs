mod vpn_client;
#[cfg(target_os = "windows")]
mod windows_service;

use anyhow::Result;
use clap::{Parser, Subcommand};
use common::config::ClientConfig;
use std::path::PathBuf;
use tokio::fs;
use tracing::{error, info};
use tracing_subscriber::EnvFilter;
use vpn_client::VpnClient;

#[derive(Parser, Debug)]
#[clap(author, version, about)]
struct Args {
    #[clap(subcommand)]
    command: Option<Command>,

    #[clap(short, long, default_value = "client_config.json")]
    config: PathBuf,
}

#[derive(Subcommand, Debug)]
enum Command {
    /// Create a new configuration file
    Init {
        #[clap(short, long)]
        server: String,
        
        #[clap(short, long)]
        username: String,
        
        #[clap(short, long)]
        password: String,
        
        #[clap(short, long)]
        game_optimized: bool,
    },
    
    #[cfg(target_os = "windows")]
    /// Install as a Windows service
    Install,
    
    #[cfg(target_os = "windows")]
    /// Uninstall the Windows service
    Uninstall,
    
    /// Connect to VPN server
    Connect,
    
    /// Disconnect from VPN server
    Disconnect,
    
    /// Get VPN status
    Status,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    
    match args.command {
        Some(Command::Init { server, username, password, game_optimized }) => {
            create_config(&args.config, server, username, password, game_optimized).await?;
            println!("Configuration file created at: {}", args.config.display());
            return Ok(());
        },
        
        #[cfg(target_os = "windows")]
        Some(Command::Install) => {
            windows_service::install_service()?;
            println!("Service installed successfully");
            return Ok(());
        },
        
        #[cfg(target_os = "windows")]
        Some(Command::Uninstall) => {
            windows_service::uninstall_service()?;
            println!("Service uninstalled successfully");
            return Ok(());
        },
        
        Some(Command::Status) => {
            println!("VPN status: Not implemented yet");
            return Ok(());
        },
        
        Some(Command::Disconnect) => {
            println!("VPN disconnected");
            return Ok(());
        },
        
        Some(Command::Connect) | None => {
            // Load config and connect
        },
    }
    
    // Load configuration
    if !args.config.exists() {
        error!("Configuration file not found at: {}", args.config.display());
        error!("Run with 'init' command to create a configuration file");
        return Ok(());
    }
    
    let config = ClientConfig::load(args.config.to_str().unwrap())?;
    
    // Initialize logging
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| {
        EnvFilter::new(config.log_level.clone())
    });
    
    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .init();
    
    info!("Starting QUIC VPN Client v{}", env!("CARGO_PKG_VERSION"));
    
    // Create VPN client
    let mut client = VpnClient::new(config.clone());
    
    // Connect to server
    match client.connect().await {
        Ok(_) => {
            info!("Connected to server: {}", config.server_addr);
            
            // Wait for client to disconnect
            client.wait_for_disconnect().await?;
        }
        Err(e) => {
            error!("Failed to connect to server: {}", e);
        }
    }
    
    Ok(())
}

async fn create_config(
    path: &PathBuf,
    server: String,
    username: String,
    password: String,
    game_optimized: bool,
) -> Result<()> {
    let server_addr = server.parse()?;
    
    let config = ClientConfig {
        server_addr,
        server_hostname: "quicvpn.server".to_string(),
        server_cert_path: None,
        username,
        password,
        log_level: "info".to_string(),
        interface_name: None,
        gaming_optimization: game_optimized,
        game_type: if game_optimized { Some("default".to_string()) } else { None },
    };
    
    config.save(path.to_str().unwrap())?;
    
    Ok(())
} 