use serde::{Deserialize, Serialize};
use std::net::{IpAddr, SocketAddr};
use std::path::PathBuf;
use std::fs;
use crate::error::VpnError;
use crate::Result;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServerConfig {
    pub listen_addr: SocketAddr,
    pub cert_path: PathBuf,
    pub key_path: PathBuf,
    pub vpn_network: IpAddr,
    pub vpn_netmask: IpAddr,
    pub mtu: u16,
    pub log_level: String,
    pub user_db_path: PathBuf,
    pub max_clients: usize,
    pub gaming_optimization: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ClientConfig {
    pub server_addr: SocketAddr,
    pub server_hostname: String,
    pub server_cert_path: Option<PathBuf>,
    pub username: String,
    pub password: String,
    pub log_level: String,
    pub interface_name: Option<String>,
    pub gaming_optimization: bool,
    pub game_type: Option<String>,
}

impl ServerConfig {
    pub fn load(path: &str) -> Result<Self> {
        let content = fs::read_to_string(path)
            .map_err(|e| VpnError::Config(format!("Failed to read config file: {}", e)))?;
        
        serde_json::from_str(&content)
            .map_err(|e| VpnError::Config(format!("Failed to parse config: {}", e)))
    }

    pub fn save(&self, path: &str) -> Result<()> {
        let content = serde_json::to_string_pretty(self)
            .map_err(|e| VpnError::Config(format!("Failed to serialize config: {}", e)))?;
        
        fs::write(path, content)
            .map_err(|e| VpnError::Config(format!("Failed to write config file: {}", e)))
    }
}

impl ClientConfig {
    pub fn load(path: &str) -> Result<Self> {
        let content = fs::read_to_string(path)
            .map_err(|e| VpnError::Config(format!("Failed to read config file: {}", e)))?;
        
        serde_json::from_str(&content)
            .map_err(|e| VpnError::Config(format!("Failed to parse config: {}", e)))
    }

    pub fn save(&self, path: &str) -> Result<()> {
        let content = serde_json::to_string_pretty(self)
            .map_err(|e| VpnError::Config(format!("Failed to serialize config: {}", e)))?;
        
        fs::write(path, content)
            .map_err(|e| VpnError::Config(format!("Failed to write config file: {}", e)))
    }
} 