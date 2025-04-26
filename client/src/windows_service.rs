use anyhow::Result;
use std::ffi::OsString;
use windows_service::{
    define_windows_service,
    service::{
        ServiceAccess, ServiceControl, ServiceControlAccept, ServiceExitCode, ServiceInfo,
        ServiceState, ServiceStatus, ServiceType,
    },
    service_control_handler::{self, ServiceControlHandlerResult},
    service_dispatcher,
    service_manager::{ServiceManager, ServiceManagerAccess},
};

const SERVICE_NAME: &str = "QuicVpnService";
const SERVICE_DISPLAY_NAME: &str = "QUIC VPN Gaming Service";
const SERVICE_DESCRIPTION: &str = "A scalable QUIC VPN optimized for gaming";

define_windows_service!(ffi_service_main, service_main);

pub fn install_service() -> Result<()> {
    let manager = ServiceManager::local_computer(None::<&str>, ServiceManagerAccess::CREATE_SERVICE)?;
    
    let service_binary_path = std::env::current_exe()?;
    
    let service_info = ServiceInfo {
        name: OsString::from(SERVICE_NAME),
        display_name: OsString::from(SERVICE_DISPLAY_NAME),
        service_type: ServiceType::OWN_PROCESS,
        start_type: windows_service::service::ServiceStartType::AutoStart,
        error_control: windows_service::service::ServiceErrorControl::Normal,
        executable_path: service_binary_path,
        launch_arguments: vec![OsString::from("--service")],
        dependencies: vec![],
        account_name: None,
        account_password: None,
    };
    
    let service = manager.create_service(&service_info, ServiceAccess::CHANGE_CONFIG)?;
    service.set_description(SERVICE_DESCRIPTION)?;
    
    println!("Service installed successfully");
    
    Ok(())
}

pub fn uninstall_service() -> Result<()> {
    let manager = ServiceManager::local_computer(None::<&str>, ServiceManagerAccess::CONNECT)?;
    
    let service = manager.open_service(SERVICE_NAME, ServiceAccess::DELETE)?;
    service.delete()?;
    
    println!("Service uninstalled successfully");
    
    Ok(())
}

pub fn run_service() -> Result<()> {
    // Register generated `ffi_service_main` with the system and start the service, blocking
    // this thread until the service is stopped.
    service_dispatcher::start(SERVICE_NAME, ffi_service_main)?;
    
    Ok(())
}

fn service_main(_arguments: Vec<OsString>) {
    if let Err(e) = run_service_main() {
        eprintln!("Service main function failed: {}", e);
    }
}

fn run_service_main() -> Result<()> {
    // Initialize the event handler
    let event_handler = move |control_event| -> ServiceControlHandlerResult {
        match control_event {
            ServiceControl::Stop => {
                // Handle stop event
                ServiceControlHandlerResult::NoError
            }
            ServiceControl::Interrogate => ServiceControlHandlerResult::NoError,
            _ => ServiceControlHandlerResult::NotImplemented,
        }
    };
    
    let status_handle = service_control_handler::register(SERVICE_NAME, event_handler)?;
    
    // Tell the system that the service is running
    status_handle.set_service_status(ServiceStatus {
        service_type: ServiceType::OWN_PROCESS,
        current_state: ServiceState::Running,
        controls_accepted: ServiceControlAccept::STOP,
        exit_code: ServiceExitCode::Win32(0),
        checkpoint: 0,
        wait_hint: std::time::Duration::default(),
        process_id: None,
    })?;
    
    // Here you would initialize and run your VPN client
    // This is just a placeholder
    let config_path = "client_config.json";
    
    // Load config and start the VPN client in a background thread
    let _vpn_thread = std::thread::spawn(move || {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            // Load config
            match common::config::ClientConfig::load(config_path) {
                Ok(config) => {
                    // Create and run VPN client
                    let mut client = crate::vpn_client::VpnClient::new(config);
                    if let Err(e) = client.connect().await {
                        eprintln!("Failed to connect to VPN server: {}", e);
                    }
                    
                    // Wait for disconnect signal
                    let _ = client.wait_for_disconnect().await;
                }
                Err(e) => {
                    eprintln!("Failed to load config: {}", e);
                }
            }
        });
    });
    
    // Block this thread until we receive a stop signal
    loop {
        std::thread::sleep(std::time::Duration::from_secs(1));
    }
}

pub fn stop_service() -> Result<()> {
    let manager = ServiceManager::local_computer(None::<&str>, ServiceManagerAccess::CONNECT)?;
    let service = manager.open_service(SERVICE_NAME, ServiceAccess::STOP)?;
    
    service.stop()?;
    
    Ok(())
} 