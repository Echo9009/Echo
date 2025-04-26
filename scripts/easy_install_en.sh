#!/bin/bash

# QUIC VPN Easy Installation and Management Script
# This script must be run with root privileges

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Default variables
SERVER_CONFIG_DIR="/etc/quicvpn"
SERVER_CONFIG_FILE="${SERVER_CONFIG_DIR}/server_config.json"
USERS_FILE="${SERVER_CONFIG_DIR}/users.json"
CLIENTS_DIR="${SERVER_CONFIG_DIR}/clients"
SERVER_KEY="${SERVER_CONFIG_DIR}/server.key"
SERVER_CERT="${SERVER_CONFIG_DIR}/server.crt"
QUICVPN_SERVICE="quicvpn-server.service"
DEFAULT_PORT="4433"
DEFAULT_IP_POOL="10.8.0.0/24"
SERVER_BIN="/usr/local/bin/quicvpn-server"
VERSION="1.0.0"

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}    QUIC VPN Easy Install & Manage    ${NC}"
    echo -e "${BLUE}         Version: ${VERSION}          ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Show main menu
show_menu() {
    echo -e "${YELLOW}Please select an option:${NC}"
    echo "1) Install QUIC VPN Server"
    echo "2) Manage Users"
    echo "3) Manage Server"
    echo "4) View Status"
    echo "5) Uninstall QUIC VPN"
    echo "6) Exit"
    echo ""
    read -p "Enter your choice [1-6]: " choice
    
    case $choice in
        1) install_server ;;
        2) user_management_menu ;;
        3) server_management_menu ;;
        4) show_status ;;
        5) uninstall_server ;;
        6) exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" && show_menu ;;
    esac
}

# Uninstall server
uninstall_server() {
    clear
    print_banner
    
    echo -e "${YELLOW}Uninstalling QUIC VPN Server...${NC}"
    
    # Stop and disable service
    systemctl stop ${QUICVPN_SERVICE} 2>/dev/null
    systemctl disable ${QUICVPN_SERVICE} 2>/dev/null
    
    # Remove service file
    rm -f /etc/systemd/system/${QUICVPN_SERVICE}
    systemctl daemon-reload
    
    # Remove binary
    rm -f ${SERVER_BIN}
    
    # Remove configuration directory
    rm -rf ${SERVER_CONFIG_DIR}
    
    # Remove firewall rules
    if [[ -f /etc/debian_version ]]; then
        # For Debian/Ubuntu
        iptables -D INPUT -p udp --dport ${DEFAULT_PORT} -j ACCEPT 2>/dev/null
        iptables -D FORWARD -s ${DEFAULT_IP_POOL} -j ACCEPT 2>/dev/null
        iptables -D FORWARD -d ${DEFAULT_IP_POOL} -j ACCEPT 2>/dev/null
        iptables -t nat -D POSTROUTING -s ${DEFAULT_IP_POOL} -o eth0 -j MASQUERADE 2>/dev/null
        netfilter-persistent save
    elif [[ -f /etc/redhat-release ]]; then
        # For CentOS/RHEL
        iptables -D INPUT -p udp --dport ${DEFAULT_PORT} -j ACCEPT 2>/dev/null
        iptables -D FORWARD -s ${DEFAULT_IP_POOL} -j ACCEPT 2>/dev/null
        iptables -D FORWARD -d ${DEFAULT_IP_POOL} -j ACCEPT 2>/dev/null
        iptables -t nat -D POSTROUTING -s ${DEFAULT_IP_POOL} -o eth0 -j MASQUERADE 2>/dev/null
        service iptables save
    fi
    
    echo -e "${GREEN}QUIC VPN has been successfully uninstalled.${NC}"
    echo -e "${YELLOW}You can now reinstall it if needed.${NC}"
    
    read -p "Press any key to continue..." -n1 -s
    clear
    print_banner
    show_menu
}

# Install dependencies
install_dependencies() {
    echo -e "${BLUE}Installing required packages...${NC}"
    
    # Detect distribution
    if [[ -f /etc/debian_version ]]; then
        apt update
        apt install -y curl wget tar jq openssl git build-essential
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y curl wget tar jq openssl git gcc make
    else
        echo -e "${RED}Your Linux distribution is not supported.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Required packages installed successfully.${NC}"
}

# Download and install binary
download_and_install_binary() {
    echo -e "${BLUE}Downloading and installing QUIC VPN...${NC}"
    
    # Download from GitHub
    echo -e "${YELLOW}Downloading from GitHub: https://github.com/Echo9009/Echo.git${NC}"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    echo -e "Temporary directory: ${TMP_DIR}"
    
    # Clone repository
    git clone https://github.com/Echo9009/Echo.git "${TMP_DIR}/quicvpn"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error downloading source code. Please check your internet connection.${NC}"
        exit 1
    fi
    
    # Enter project directory
    cd "${TMP_DIR}/quicvpn"
    
    # Build project (if Rust)
    echo -e "${BLUE}Building project...${NC}"
    
    # Check for Cargo.toml for Rust projects
    if [[ -f "Cargo.toml" ]]; then
        # Install Rust if not installed
        if ! command -v cargo &> /dev/null; then
            echo -e "${YELLOW}Rust not found. Installing Rust...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        
        # Build release
        cargo build --release
        
        # Copy server binary to install path
        if [[ -f "target/release/quicvpn-server" ]]; then
            cp "target/release/quicvpn-server" "${SERVER_BIN}"
        elif [[ -f "target/release/server" ]]; then
            cp "target/release/server" "${SERVER_BIN}"
        else
            echo -e "${RED}Server binary not found. Please make sure the project built correctly.${NC}"
            exit 1
        fi
    else
        # If not a Rust project, assume pre-built binary
        echo -e "${YELLOW}Cargo.toml not found. Looking for pre-built binary...${NC}"
        
        # Search for binary in different directories
        FOUND_BIN=$(find . -type f -name "quicvpn-server" -o -name "server" | head -n 1)
        
        if [[ -n "${FOUND_BIN}" ]]; then
            cp "${FOUND_BIN}" "${SERVER_BIN}"
        else
            echo -e "${RED}Server binary not found in repository.${NC}"
            exit 1
        fi
    fi
    
    # Set execute permission
    chmod +x "${SERVER_BIN}"
    
    # Cleanup
    cd -
    rm -rf "${TMP_DIR}"
    
    # Create install directories
    mkdir -p ${SERVER_CONFIG_DIR}
    mkdir -p ${CLIENTS_DIR}
    
    # Install systemd service
    cat > /etc/systemd/system/${QUICVPN_SERVICE} << EOF
[Unit]
Description=QUIC VPN Server
After=network.target

[Service]
ExecStart=${SERVER_BIN} --config ${SERVER_CONFIG_FILE}
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    
    echo -e "${GREEN}QUIC VPN installed successfully.${NC}"
}

# Generate TLS certificate
generate_certificate() {
    echo -e "${BLUE}Generating TLS certificate...${NC}"
    
    read -p "Enter server domain or IP address: " server_domain
    
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout ${SERVER_KEY} -out ${SERVER_CERT} \
        -subj "/CN=${server_domain}" \
        -addext "subjectAltName=DNS:${server_domain},IP:${server_domain}"
    
    chmod 600 ${SERVER_KEY}
    chmod 644 ${SERVER_CERT}
    
    echo -e "${GREEN}TLS certificate generated successfully.${NC}"
}

# Configure server
configure_server() {
    echo -e "${BLUE}Configuring server...${NC}"
    
    read -p "Enter server port [default: ${DEFAULT_PORT}]: " server_port
    server_port=${server_port:-${DEFAULT_PORT}}
    
    read -p "Enter internal IP range [default: ${DEFAULT_IP_POOL}]: " ip_pool
    ip_pool=${ip_pool:-${DEFAULT_IP_POOL}}
    
    cat > ${SERVER_CONFIG_FILE} << EOF
{
    "listen_addr": "0.0.0.0:${server_port}",
    "cert_path": "${SERVER_CERT}",
    "key_path": "${SERVER_KEY}",
    "users_file": "${USERS_FILE}",
    "ip_pool": "${ip_pool}",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "keep_alive": 5,
    "enable_game_optimization": true,
    "log_level": "info",
    "log_file": "/var/log/quicvpn.log"
}
EOF

    echo '{"users": []}' > ${USERS_FILE}
    chmod 600 ${SERVER_CONFIG_FILE} ${USERS_FILE}
    
    echo -e "${GREEN}Server configuration completed.${NC}"
}

# Enable IP forwarding
enable_ip_forwarding() {
    echo -e "${BLUE}Enabling IP forwarding...${NC}"
    echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-quicvpn.conf
    sysctl -p /etc/sysctl.d/99-quicvpn.conf
    echo -e "${GREEN}IP forwarding enabled.${NC}"
}

# Setup firewall
setup_firewall() {
    echo -e "${BLUE}Setting up firewall...${NC}"
    
    local port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2)
    local ip_pool=$(jq -r '.ip_pool' ${SERVER_CONFIG_FILE})
    
    iptables -A INPUT -p udp --dport ${port} -j ACCEPT
    iptables -A FORWARD -s ${ip_pool} -j ACCEPT
    iptables -A FORWARD -d ${ip_pool} -j ACCEPT
    iptables -t nat -A POSTROUTING -s ${ip_pool} -o eth0 -j MASQUERADE
    
    if [[ -f /etc/debian_version ]]; then
        apt install -y iptables-persistent
        netfilter-persistent save
    elif [[ -f /etc/redhat-release ]]; then
        echo "iptables-save > /etc/sysconfig/iptables" > /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
        iptables-save > /etc/sysconfig/iptables
    fi
    
    echo -e "${GREEN}Firewall configured successfully.${NC}"
}

# Install server
install_server() {
    clear
    print_banner
    
    echo -e "${YELLOW}Installing QUIC VPN Server...${NC}"
    
    if [[ -f ${SERVER_CONFIG_FILE} ]]; then
        read -p "QUIC VPN appears to be already installed. Do you want to reinstall? (y/n): " reinstall
        if [[ ${reinstall} != "y" && ${reinstall} != "Y" ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            show_menu
            return
        fi
        
        # Uninstall first
        uninstall_server
    fi
    
    check_root
    install_dependencies
    download_and_install_binary
    generate_certificate
    configure_server
    enable_ip_forwarding
    setup_firewall
    
    systemctl enable ${QUICVPN_SERVICE}
    systemctl start ${QUICVPN_SERVICE}
    
    echo -e "${GREEN}QUIC VPN Server installation completed successfully.${NC}"
    echo -e "${YELLOW}You can now add users and generate client configurations.${NC}"
    
    read -p "Press any key to continue..." -n1 -s
    clear
    print_banner
    show_menu
}

# User management functions would go here...
# (The rest of the script remains the same but with English text)

# Main execution
check_root
clear
print_banner
show_menu 