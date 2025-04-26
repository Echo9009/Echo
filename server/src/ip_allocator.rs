use std::collections::HashSet;
use std::net::IpAddr;
use std::sync::{Arc, Mutex};

/// Allocates and manages IP addresses for clients
#[derive(Clone)]
pub struct IpAllocator {
    base_network: IpAddr,
    netmask: IpAddr,
    used_ips: Arc<Mutex<HashSet<IpAddr>>>,
    max_clients: usize,
}

impl IpAllocator {
    pub fn new(base_network: IpAddr, netmask: IpAddr, max_clients: usize) -> Self {
        Self {
            base_network,
            netmask,
            used_ips: Arc::new(Mutex::new(HashSet::new())),
            max_clients,
        }
    }

    /// Allocate a new IP address for a client
    pub fn allocate_ip(&self) -> Option<IpAddr> {
        let mut used_ips = self.used_ips.lock().unwrap();
        
        if used_ips.len() >= self.max_clients {
            return None;
        }
        
        match self.base_network {
            IpAddr::V4(base) => {
                let base_u32: u32 = u32::from_be_bytes(base.octets());
                
                // Skip the first IP (network address) and the last IP (broadcast)
                for i in 1..self.max_clients + 1 {
                    let ip_u32 = base_u32 + i as u32;
                    let ip = IpAddr::V4(std::net::Ipv4Addr::from(ip_u32.to_be_bytes()));
                    
                    if !used_ips.contains(&ip) {
                        used_ips.insert(ip);
                        return Some(ip);
                    }
                }
                
                None
            }
            IpAddr::V6(_) => {
                // IPv6 not implemented yet
                None
            }
        }
    }

    /// Release an IP address back to the pool
    pub fn release_ip(&self, ip: IpAddr) -> bool {
        let mut used_ips = self.used_ips.lock().unwrap();
        used_ips.remove(&ip)
    }
} 