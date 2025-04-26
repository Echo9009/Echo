use thiserror::Error;

#[derive(Error, Debug)]
pub enum VpnError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Quinn error: {0}")]
    Quinn(#[from] quinn::ConnectionError),
    
    #[error("TLS error: {0}")]
    Tls(#[from] rustls::Error),
    
    #[error("Certificate error: {0}")]
    Certificate(String),
    
    #[error("JSON serialization error: {0}")]
    Json(#[from] serde_json::Error),
    
    #[error("TUN device error: {0}")]
    Tun(String),
    
    #[error("Protocol error: {0}")]
    Protocol(String),
    
    #[error("Authentication error: {0}")]
    Auth(String),
    
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("Connection closed")]
    ConnectionClosed,
    
    #[error("Unknown error: {0}")]
    Unknown(String),
} 