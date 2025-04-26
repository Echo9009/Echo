#!/bin/bash

# QUIC VPN Easy Installation and User Management Script
# This script must be run with root privileges

# Output color settings
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

# Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}     QUIC VPN Easy Install & Manage     ${NC}"
    echo -e "${BLUE}        Version: ${VERSION}              ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Display main menu
show_menu() {
    echo -e "${YELLOW}Please select an option:${NC}"
    echo "1) Install QUIC VPN Server"
    echo "2) User Management"
    echo "3) Server Management"
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

# User management menu
user_management_menu() {
    clear
    print_banner
    echo -e "${YELLOW}User Management Menu:${NC}"
    echo "1) Add New User"
    echo "2) Remove User"
    echo "3) List Users"
    echo "4) Generate Client Config"
    echo "5) Return to Main Menu"
    echo ""
    read -p "Enter your choice [1-5]: " choice
    
    case $choice in
        1) add_user ;;
        2) remove_user ;;
        3) list_users ;;
        4) generate_client_config ;;
        5) clear && print_banner && show_menu ;;
        *) echo -e "${RED}Invalid option!${NC}" && user_management_menu ;;
    esac
}

# Server management menu
server_management_menu() {
    clear
    print_banner
    echo -e "${YELLOW}Server Management Menu:${NC}"
    echo "1) Start Server"
    echo "2) Stop Server"
    echo "3) Restart Server"
    echo "4) View Server Logs"
    echo "5) Return to Main Menu"
    echo ""
    read -p "Enter your choice [1-5]: " choice
    
    case $choice in
        1) start_server ;;
        2) stop_server ;;
        3) restart_server ;;
        4) show_logs ;;
        5) clear && print_banner && show_menu ;;
        *) echo -e "${RED}Invalid option!${NC}" && server_management_menu ;;
    esac
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

# Download and install QUIC VPN binary
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
        
        # Build in release mode
        cargo build --release
        
        # Copy server binary to installation path
        if [[ -f "target/release/quicvpn-server" ]]; then
            cp "target/release/quicvpn-server" "${SERVER_BIN}"
        elif [[ -f "target/release/server" ]]; then
            cp "target/release/server" "${SERVER_BIN}"
        else
            echo -e "${RED}Server binary not found. Please make sure the project built correctly.${NC}"
            exit 1
        fi
    else
        # If not a Rust project, assume it has ready binaries
        echo -e "${YELLOW}Cargo.toml not found. Looking for ready binaries...${NC}"
        
        # Search for binary in different directories
        FOUND_BIN=$(find . -type f -name "quicvpn-server" -o -name "server" | head -n 1)
        
        if [[ -n "${FOUND_BIN}" ]]; then
            cp "${FOUND_BIN}" "${SERVER_BIN}"
        else
            echo -e "${RED}Server binary not found in repository.${NC}"
            exit 1
        fi
    fi
    
    # Make binary executable
    chmod +x "${SERVER_BIN}"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "${TMP_DIR}"
    
    # Create installation directories
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

# Generate self-signed TLS certificate for server
generate_certificate() {
    echo -e "${BLUE}Generating TLS certificate...${NC}"
    
    # Get server domain or IP
    read -p "Enter server domain or IP address: " server_domain
    
    # Create private key and certificate
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout ${SERVER_KEY} -out ${SERVER_CERT} \
        -subj "/CN=${server_domain}" \
        -addext "subjectAltName=DNS:${server_domain},IP:${server_domain}"
    
    # Set file permissions
    chmod 600 ${SERVER_KEY}
    chmod 644 ${SERVER_CERT}
    
    echo -e "${GREEN}TLS certificate generated successfully.${NC}"
}

# Initial server configuration
configure_server() {
    echo -e "${BLUE}Configuring server...${NC}"
    
    # Get configuration parameters
    read -p "Enter server port [default: ${DEFAULT_PORT}]: " server_port
    server_port=${server_port:-${DEFAULT_PORT}}
    
    read -p "Enter internal IP range [default: ${DEFAULT_IP_POOL}]: " ip_pool
    ip_pool=${ip_pool:-${DEFAULT_IP_POOL}}
    
    # Create server configuration file
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

    # Create empty users file
    echo '{"users": []}' > ${USERS_FILE}
    
    # Set file permissions
    chmod 600 ${SERVER_CONFIG_FILE} ${USERS_FILE}
    
    echo -e "${GREEN}Server configuration completed successfully.${NC}"
}

# Enable IP Forwarding
enable_ip_forwarding() {
    echo -e "${BLUE}Enabling IP Forwarding...${NC}"
    
    # Enable IP Forwarding
    echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-quicvpn.conf
    sysctl -p /etc/sysctl.d/99-quicvpn.conf
    
    echo -e "${GREEN}IP Forwarding enabled successfully.${NC}"
}

# Setup firewall rules
setup_firewall() {
    echo -e "${BLUE}Setting up firewall...${NC}"
    
    # Read port from config file
    local port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2)
    local ip_pool=$(jq -r '.ip_pool' ${SERVER_CONFIG_FILE})
    
    # Add iptables rules
    iptables -A INPUT -p udp --dport ${port} -j ACCEPT
    iptables -A FORWARD -s ${ip_pool} -j ACCEPT
    iptables -A FORWARD -d ${ip_pool} -j ACCEPT
    iptables -t nat -A POSTROUTING -s ${ip_pool} -o eth0 -j MASQUERADE
    
    # Save iptables rules
    if [[ -f /etc/debian_version ]]; then
        apt install -y iptables-persistent
        netfilter-persistent save
    elif [[ -f /etc/redhat-release ]]; then
        echo "iptables-save > /etc/sysconfig/iptables" > /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
        iptables-save > /etc/sysconfig/iptables
    fi
    
    echo -e "${GREEN}Firewall setup completed successfully.${NC}"
}

# Install QUIC VPN server
install_server() {
    clear
    print_banner
    
    echo -e "${YELLOW}Installing QUIC VPN Server...${NC}"
    
    # Check if already installed
    if [[ -f ${SERVER_CONFIG_FILE} ]]; then
        read -p "QUIC VPN appears to be already installed. Do you want to reinstall? (y/n): " reinstall
        if [[ ${reinstall} != "y" && ${reinstall} != "Y" ]]; then
            echo -e "${YELLOW}Installation canceled.${NC}"
            show_menu
            return
        fi
    fi
    
    # Installation steps
    check_root
    install_dependencies
    download_and_install_binary
    generate_certificate
    configure_server
    enable_ip_forwarding
    setup_firewall
    
    # Enable and start service
    systemctl enable ${QUICVPN_SERVICE}
    systemctl start ${QUICVPN_SERVICE}
    
    echo -e "${GREEN}QUIC VPN Server installed successfully.${NC}"
    echo -e "${YELLOW}You can now add users and generate client configuration files.${NC}"
    
    read -p "Press any key to continue..." -n1 -s
    clear
    print_banner
    show_menu
}

# Uninstall QUIC VPN server
uninstall_server() {
    clear
    print_banner
    
    echo -e "${YELLOW}Uninstalling QUIC VPN Server...${NC}"
    
    # Confirm uninstallation
    read -p "Are you sure you want to uninstall QUIC VPN? This will remove all configuration and user data. (y/n): " confirm
    if [[ ${confirm} != "y" && ${confirm} != "Y" ]]; then
        echo -e "${YELLOW}Uninstallation canceled.${NC}"
        show_menu
        return
    fi
    
    # Stop and disable service
    echo -e "${BLUE}Stopping QUIC VPN service...${NC}"
    systemctl stop ${QUICVPN_SERVICE} 2>/dev/null
    systemctl disable ${QUICVPN_SERVICE} 2>/dev/null
    
    # Remove service file
    echo -e "${BLUE}Removing service files...${NC}"
    rm -f /etc/systemd/system/${QUICVPN_SERVICE}
    systemctl daemon-reload
    
    # Remove firewall rules
    echo -e "${BLUE}Removing firewall rules...${NC}"
    if [[ -f ${SERVER_CONFIG_FILE} ]]; then
        local port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} 2>/dev/null | cut -d':' -f2)
        local ip_pool=$(jq -r '.ip_pool' ${SERVER_CONFIG_FILE} 2>/dev/null)
        
        if [[ -n "${port}" && -n "${ip_pool}" ]]; then
            iptables -D INPUT -p udp --dport ${port} -j ACCEPT 2>/dev/null
            iptables -D FORWARD -s ${ip_pool} -j ACCEPT 2>/dev/null
            iptables -D FORWARD -d ${ip_pool} -j ACCEPT 2>/dev/null
            iptables -t nat -D POSTROUTING -s ${ip_pool} -o eth0 -j MASQUERADE 2>/dev/null
            
            # Save iptables rules
            if [[ -f /etc/debian_version ]]; then
                netfilter-persistent save 2>/dev/null
            elif [[ -f /etc/redhat-release ]]; then
                iptables-save > /etc/sysconfig/iptables 2>/dev/null
            fi
        fi
    fi
    
    # Disable IP forwarding
    echo -e "${BLUE}Disabling IP forwarding...${NC}"
    rm -f /etc/sysctl.d/99-quicvpn.conf
    sysctl -p 2>/dev/null
    
    # Remove binary
    echo -e "${BLUE}Removing QUIC VPN binary...${NC}"
    rm -f ${SERVER_BIN}
    
    # Remove configuration files
    echo -e "${BLUE}Removing configuration files...${NC}"
    rm -rf ${SERVER_CONFIG_DIR}
    
    echo -e "${GREEN}QUIC VPN Server uninstalled successfully.${NC}"
    
    read -p "Press any key to continue..." -n1 -s
    clear
    print_banner
    show_menu
}

# Add new user
add_user() {
    clear
    print_banner
    
    echo -e "${YELLOW}Add New User:${NC}"
    
    # Check for users file
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}Users file not found. Please install the server first.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Get user information
    read -p "Username: " username
    
    # Check for duplicate username
    if jq -e --arg user "${username}" '.users[] | select(.username == $user)' ${USERS_FILE} > /dev/null; then
        echo -e "${RED}This username already exists.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Generate random password
    password=$(openssl rand -hex 8)
    
    # Generate UUID for user
    user_id=$(cat /proc/sys/kernel/random/uuid)
    
    # Add user to users file
    jq --arg username "${username}" \
       --arg password "${password}" \
       --arg user_id "${user_id}" \
       '.users += [{"username": $username, "password": $password, "user_id": $user_id, "enabled": true}]' ${USERS_FILE} > ${USERS_FILE}.tmp
    
    mv ${USERS_FILE}.tmp ${USERS_FILE}
    
    # Apply changes
    restart_server
    
    echo -e "${GREEN}User '${username}' added successfully.${NC}"
    echo -e "${YELLOW}Username: ${username}${NC}"
    echo -e "${YELLOW}Password: ${password}${NC}"
    
    # Generate client config file
    generate_config_for_user "${username}" "${password}"
    
    read -p "Press any key to continue..." -n1 -s
    user_management_menu
}

# Remove user
remove_user() {
    clear
    print_banner
    
    echo -e "${YELLOW}Remove User:${NC}"
    
    # Check for users file
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}Users file not found. Please install the server first.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Display user list
    list_users_simple
    
    # Get username to remove
    read -p "Enter username to remove: " username
    
    # Check if user exists
    if ! jq -e --arg user "${username}" '.users[] | select(.username == $user)' ${USERS_FILE} > /dev/null; then
        echo -e "${RED}User not found.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Remove user from users file
    jq --arg user "${username}" '.users = [.users[] | select(.username != $user)]' ${USERS_FILE} > ${USERS_FILE}.tmp
    
    mv ${USERS_FILE}.tmp ${USERS_FILE}
    
    # Remove user config file if exists
    if [[ -f "${CLIENTS_DIR}/${username}.json" ]]; then
        rm "${CLIENTS_DIR}/${username}.json"
    fi
    
    # Apply changes
    restart_server
    
    echo -e "${GREEN}User '${username}' removed successfully.${NC}"
    
    read -p "Press any key to continue..." -n1 -s
    user_management_menu
}

# Simple user list display
list_users_simple() {
    echo "Available users:"
    echo "--------------------------"
    
    if [[ ! -f ${USERS_FILE} ]]; then
        echo "No users found."
        return
    fi
    
    jq -r '.users[] | "\(.username) (\(if .enabled then "enabled" else "disabled" end))"' ${USERS_FILE}
    echo "--------------------------"
}

# List users
list_users() {
    clear
    print_banner
    
    echo -e "${YELLOW}User List:${NC}"
    
    # Check for users file
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}Users file not found. Please install the server first.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Display user count
    user_count=$(jq '.users | length' ${USERS_FILE})
    echo -e "${GREEN}Total users: ${user_count}${NC}"
    
    # Display user details
    echo -e "\n${BLUE}User Details:${NC}"
    jq -r '.users[] | "Username: \(.username)\nStatus: \(if .enabled then "Enabled" else "Disabled" end)\nID: \(.user_id)\n-------------------"' ${USERS_FILE}
    
    read -p "Press any key to continue..." -n1 -s
    user_management_menu
}

# Generate config file for a user
generate_config_for_user() {
    local username="$1"
    local password="$2"
    
    # Get server information
    local server_ip=$(curl -s ifconfig.me)
    local server_port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2)
    
    # Create directory for config files if it doesn't exist
    mkdir -p ${CLIENTS_DIR}
    
    # Create client config file
    cat > "${CLIENTS_DIR}/${username}.json" << EOF
{
    "server_addr": "${server_ip}:${server_port}",
    "username": "${username}",
    "password": "${password}",
    "allow_insecure": true,
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "auto_reconnect": true,
    "gaming_optimization": true,
    "log_level": "info"
}
EOF
    
    echo -e "${GREEN}Client configuration file for user '${username}' created at ${CLIENTS_DIR}/${username}.json${NC}"
    echo -e "${YELLOW}Use the following command to connect:${NC}"
    echo -e "${BLUE}quicvpn-client --config ${username}.json${NC}"
}

# Generate client configuration
generate_client_config() {
    clear
    print_banner
    
    echo -e "${YELLOW}Generate Client Configuration:${NC}"
    
    # Check for users file
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}Users file not found. Please install the server first.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Display user list
    list_users_simple
    
    # Get username
    read -p "Enter username to generate configuration: " username
    
    # Check if user exists
    if ! jq -e --arg user "${username}" '.users[] | select(.username == $user)' ${USERS_FILE} > /dev/null; then
        echo -e "${RED}User not found.${NC}"
        read -p "Press any key to continue..." -n1 -s
        user_management_menu
        return
    fi
    
    # Get user password
    password=$(jq -r --arg user "${username}" '.users[] | select(.username == $user) | .password' ${USERS_FILE})
    
    # Generate configuration file
    generate_config_for_user "${username}" "${password}"
    
    # Show download path
    echo -e "${YELLOW}Configuration file path: ${CLIENTS_DIR}/${username}.json${NC}"
    echo -e "${YELLOW}You can send this file to the user.${NC}"
    
    read -p "Press any key to continue..." -n1 -s
    user_management_menu
}

# Start server
start_server() {
    echo -e "${BLUE}Starting QUIC VPN Server...${NC}"
    systemctl start ${QUICVPN_SERVICE}
    sleep 2
    
    if systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "${GREEN}QUIC VPN Server started successfully.${NC}"
    else
        echo -e "${RED}Failed to start QUIC VPN Server. Please check the logs.${NC}"
    fi
    
    read -p "Press any key to continue..." -n1 -s
    server_management_menu
}

# Stop server
stop_server() {
    echo -e "${BLUE}Stopping QUIC VPN Server...${NC}"
    systemctl stop ${QUICVPN_SERVICE}
    sleep 2
    
    if ! systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "${GREEN}QUIC VPN Server stopped successfully.${NC}"
    else
        echo -e "${RED}Failed to stop QUIC VPN Server.${NC}"
    fi
    
    read -p "Press any key to continue..." -n1 -s
    server_management_menu
}

# Restart server
restart_server() {
    echo -e "${BLUE}Restarting QUIC VPN Server...${NC}"
    systemctl restart ${QUICVPN_SERVICE}
    sleep 2
    
    if systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "${GREEN}QUIC VPN Server restarted successfully.${NC}"
    else
        echo -e "${RED}Failed to restart QUIC VPN Server. Please check the logs.${NC}"
    fi
}

# Show server logs
show_logs() {
    echo -e "${BLUE}QUIC VPN Server Logs:${NC}"
    journalctl -u ${QUICVPN_SERVICE} -n 50 --no-pager
    
    read -p "Press any key to continue..." -n1 -s
    server_management_menu
}

# Show status
show_status() {
    clear
    print_banner
    
    echo -e "${YELLOW}QUIC VPN Server Status:${NC}"
    
    # Show service status
    echo -e "${BLUE}Service Status:${NC}"
    systemctl status ${QUICVPN_SERVICE} --no-pager | head -n 3
    
    # Show connection statistics
    if systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "\n${BLUE}Connection Statistics:${NC}"
        # Custom commands to show statistics can be added here
        # For example, assume the server has an API for statistics
        if [[ -f ${USERS_FILE} ]]; then
            user_count=$(jq '.users | length' ${USERS_FILE})
            echo -e "Total users: ${user_count}"
        fi
    fi
    
    # Show network information
    echo -e "\n${BLUE}Network Information:${NC}"
    # Show server's external IP
    server_ip=$(curl -s ifconfig.me)
    server_port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2 2>/dev/null || echo "${DEFAULT_PORT}")
    echo -e "Server IP: ${server_ip}"
    echo -e "Server Port: ${server_port}"
    
    read -p "Press any key to continue..." -n1 -s
    clear
    print_banner
    show_menu
}

# Main execution
check_root
clear
print_banner
show_menu 