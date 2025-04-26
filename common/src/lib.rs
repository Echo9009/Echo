pub mod crypto;
pub mod protocol;
pub mod tun_device;
pub mod config;
pub mod error;

pub use error::VpnError;
pub type Result<T> = std::result::Result<T, VpnError>; 