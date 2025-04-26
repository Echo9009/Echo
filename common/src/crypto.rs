use rcgen::{Certificate, CertificateParams, DnType, KeyPair, PKCS_ECDSA_P256_SHA256};
use rustls::{Certificate as RustlsCert, PrivateKey, ServerConfig};
use std::sync::Arc;

use crate::error::VpnError;
use crate::Result;

pub fn generate_self_signed_cert(hostname: &str) -> Result<(Vec<u8>, Vec<u8>)> {
    let mut params = CertificateParams::new(vec![hostname.to_string()]);
    params.distinguished_name.push(DnType::CommonName, hostname);
    params.alg = &PKCS_ECDSA_P256_SHA256;

    let cert = Certificate::from_params(params).map_err(|e| VpnError::Certificate(e.to_string()))?;
    
    let cert_der = cert.serialize_der().map_err(|e| VpnError::Certificate(e.to_string()))?;
    let key_der = cert.serialize_private_key_der();
    
    Ok((cert_der, key_der))
}

pub fn load_server_config(cert_der: &[u8], key_der: &[u8]) -> Result<ServerConfig> {
    let cert = RustlsCert(cert_der.to_vec());
    let key = PrivateKey(key_der.to_vec());
    
    let mut server_config = ServerConfig::builder()
        .with_safe_defaults()
        .with_no_client_auth()
        .with_single_cert(vec![cert], key)
        .map_err(|e| VpnError::Tls(e))?;
    
    // Configure QUIC-specific parameters
    server_config.alpn_protocols = vec![b"quicvpn".to_vec()];
    
    Ok(server_config)
}

pub fn load_client_config(server_name: &str, cert_der: &[u8]) -> Result<rustls::ClientConfig> {
    let mut root_cert_store = rustls::RootCertStore::empty();
    root_cert_store.add(&RustlsCert(cert_der.to_vec()))
        .map_err(|e| VpnError::Certificate(e.to_string()))?;
    
    let mut client_config = rustls::ClientConfig::builder()
        .with_safe_defaults()
        .with_root_certificates(root_cert_store)
        .with_no_client_auth();
    
    client_config.alpn_protocols = vec![b"quicvpn".to_vec()];
    
    Ok(client_config)
} 