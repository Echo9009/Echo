use serde::{Deserialize, Serialize};
use std::net::IpAddr;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum Message {
    ClientHello {
        username: String,
        password: String,
        client_version: String,
    },
    ServerHello {
        server_version: String,
        assigned_ip: IpAddr,
        subnet_mask: IpAddr,
        mtu: u16,
    },
    PacketData(Vec<u8>),
    KeepAlive,
    Disconnect {
        reason: String,
    },
    GameOptimizationInfo {
        game_type: String,
        latency_priority: bool,
    },
    RouteUpdate {
        routes: Vec<RouteInfo>,
    },
    Stats {
        bytes_sent: u64,
        bytes_received: u64,
        packets_sent: u64,
        packets_received: u64,
        latency_ms: u32,
    },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RouteInfo {
    pub destination: IpAddr,
    pub netmask: IpAddr,
    pub gateway: Option<IpAddr>,
}

impl Message {
    pub fn to_bytes(&self) -> Result<Vec<u8>, serde_json::Error> {
        serde_json::to_vec(self)
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, serde_json::Error> {
        serde_json::from_slice(bytes)
    }
} 