use std::io::{Read, Write};
use tun::platform::Device;
use tun::Configuration;
use crate::error::VpnError;
use crate::Result;
use std::net::IpAddr;
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;

pub struct TunDevice {
    device: Arc<Mutex<Device>>,
    mtu: u16,
}

impl TunDevice {
    #[cfg(target_os = "windows")]
    pub fn new(name: Option<&str>, ip: IpAddr, netmask: IpAddr, mtu: u16) -> Result<Self> {
        let mut config = Configuration::default();
        
        if let Some(name) = name {
            config.name(name);
        }
        
        config.address(ip)
            .netmask(netmask)
            .mtu(mtu as i32)
            .up();

        let device = tun::create(&config)
            .map_err(|e| VpnError::Tun(format!("Failed to create TUN device: {}", e)))?;

        Ok(Self {
            device: Arc::new(Mutex::new(device)),
            mtu,
        })
    }

    #[cfg(target_os = "linux")]
    pub fn new(name: Option<&str>, ip: IpAddr, netmask: IpAddr, mtu: u16) -> Result<Self> {
        let mut config = Configuration::default();
        
        if let Some(name) = name {
            config.name(name);
        }
        
        config.address(ip)
            .netmask(netmask)
            .mtu(mtu as i32)
            .up();

        // Use persistent TUN on Linux
        config.platform(|config| {
            config.packet_information(false);
        });

        let device = tun::create(&config)
            .map_err(|e| VpnError::Tun(format!("Failed to create TUN device: {}", e)))?;

        Ok(Self {
            device: Arc::new(Mutex::new(device)),
            mtu,
        })
    }

    pub fn mtu(&self) -> u16 {
        self.mtu
    }

    pub fn start_reading(
        &self, 
        packet_sender: mpsc::Sender<Vec<u8>>
    ) -> Result<tokio::task::JoinHandle<Result<()>>> {
        let device = self.device.clone();
        let mtu = self.mtu;

        let handle = tokio::task::spawn_blocking(move || -> Result<()> {
            let mut buffer = vec![0u8; mtu as usize];
            let mut device = device.lock().unwrap();

            loop {
                match device.read(&mut buffer) {
                    Ok(n) => {
                        if n > 0 {
                            let packet = buffer[..n].to_vec();
                            if let Err(e) = packet_sender.blocking_send(packet) {
                                return Err(VpnError::Tun(format!("Failed to send packet: {}", e)));
                            }
                        }
                    }
                    Err(e) => {
                        return Err(VpnError::Io(e));
                    }
                }
            }
        });

        Ok(handle)
    }

    pub async fn write_packet(&self, packet: &[u8]) -> Result<usize> {
        let device = self.device.clone();
        
        tokio::task::spawn_blocking(move || -> Result<usize> {
            let mut device = device.lock().unwrap();
            device.write(packet).map_err(VpnError::Io)
        }).await.map_err(|e| VpnError::Tun(format!("Task join error: {}", e)))?
    }
} 