#!/bin/bash

# QUIC VPN Easy Installation and Management Script
# Version: 1.0.1
# Run with root privileges

# --- Configuration ---
SERVER_CONFIG_DIR="/etc/quicvpn"
SERVER_CONFIG_FILE="${SERVER_CONFIG_DIR}/server_config.json"
USERS_FILE="${SERVER_CONFIG_DIR}/users.json"
CLIENTS_DIR="${SERVER_CONFIG_DIR}/clients"
SERVER_KEY="${SERVER_CONFIG_DIR}/server.key"
SERVER_CERT="${SERVER_CONFIG_DIR}/server.crt"
QUICVPN_SERVICE="quicvpn-server.service"
SERVER_BIN="/usr/local/bin/quicvpn-server"
LOG_FILE="/var/log/quicvpn.log"
GITHUB_REPO="https://github.com/Echo9009/Echo.git"
REPO_NAME="Echo" # Adjust if the repo name differs from the user/org name

# Default values
DEFAULT_PORT="4433"
DEFAULT_IP_POOL="10.8.0.0/24"
DEFAULT_DNS_SERVERS='["8.8.8.8", "1.1.1.1"]'
DEFAULT_MTU=1400
DEFAULT_KEEPALIVE=5
DEFAULT_LOG_LEVEL="info"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Utility Functions ---

# Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root.${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    clear
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}     QUIC VPN Easy Install & Manage     ${NC}"
    echo -e "${BLUE}        Version: 1.0.1              ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Prompt user for input with validation
prompt_input() {
    local prompt_msg="$1"
    local variable_name="$2"
    local default_value="$3"
    local validation_func="$4" # Optional validation function name

    while true; do
        read -rp "${prompt_msg} [default: ${default_value}]: " input_value
        input_value=${input_value:-${default_value}} # Assign default if empty

        if [[ -n "$validation_func" ]]; then
            if "$validation_func" "$input_value"; then
                eval "$variable_name=\"$input_value\"" # Assign validated value
                break
            else
                echo -e "${RED}Invalid input. Please try again.${NC}"
            fi
        else
            eval "$variable_name=\"$input_value\"" # Assign value without validation
            break
        fi
    done
}

# Simple validation for port number
validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -gt 0 ] && [ "$port" -le 65535 ]
}

# Simple validation for IP/CIDR
validate_ip_pool() {
    local pool="$1"
    # Basic check - improve if needed
    [[ "$pool" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]
}

# Get user confirmation
confirm_action() {
    local prompt_msg="$1"
    while true; do
        read -rp "${prompt_msg} (y/n): " confirm
        case $confirm in
            [Yy]* ) return 0;; # Success (yes)
            [Nn]* ) return 1;; # Failure (no)
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Read a single character choice reliably
read_choice() {
    local prompt_msg="$1"
    local valid_options="$2"
    local choice_var="$3"

    while true; do
        # Clear buffer before reading
        while read -r -t 0.1 -n 1 discard; do : ; done 
        
        read -r -n 1 -p "${prompt_msg} [${valid_options}]: " choice
        echo "" # Newline after input

        if [[ "$choice" =~ ^[$valid_options]$ ]]; then
            eval "$choice_var=\"$choice\""
            break
        else
            echo -e "${RED}Invalid choice. Please enter one of [${valid_options}].${NC}"
        fi
    done
}

# --- Core Functionality ---

# Install dependencies
install_dependencies() {
    echo -e "${BLUE}Detecting distribution and installing dependencies...${NC}"
    if [[ -f /etc/debian_version ]]; then
        echo "Detected Debian/Ubuntu based system."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq > /dev/null
        apt-get install -y -qq curl wget tar jq openssl git build-essential iptables-persistent > /dev/null
        if ! command -v cargo &> /dev/null; then
             echo -e "${YELLOW}Rust/Cargo not found. Installing Rust...${NC}"
             curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
             source "$HOME/.cargo/env" || source "/root/.cargo/env" # Adjust for root user
        fi
    elif [[ -f /etc/redhat-release ]]; then
        echo "Detected RHEL/CentOS/Fedora based system."
        yum update -y -q > /dev/null
        yum install -y -q curl wget tar jq openssl git gcc make iptables-services > /dev/null
        if ! command -v cargo &> /dev/null; then
             echo -e "${YELLOW}Rust/Cargo not found. Installing Rust...${NC}"
             curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
             source "$HOME/.cargo/env" || source "/root/.cargo/env" # Adjust for root user
        fi
        # Enable and start iptables service if needed
        systemctl enable iptables --now 2>/dev/null
    else
        echo -e "${RED}Unsupported Linux distribution.${NC}"
        return 1
    fi
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
}

# Download and build/install QUIC VPN binary
download_and_install_binary() {
    echo -e "${BLUE}Downloading and building QUIC VPN...${NC}"
    TMP_DIR=$(mktemp -d)
    echo "Using temporary directory: ${TMP_DIR}"

    git clone --depth 1 "${GITHUB_REPO}" "${TMP_DIR}/${REPO_NAME}"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error cloning repository. Check URL and network.${NC}"
        rm -rf "${TMP_DIR}"
        return 1
    fi

    cd "${TMP_DIR}/${REPO_NAME}" || exit 1

    if [[ ! -f "Cargo.toml" ]]; then
         echo -e "${RED}Cargo.toml not found in the repository root.${NC}"
         cd - &> /dev/null; rm -rf "${TMP_DIR}"; return 1
    fi

    # Ensure Rust is in PATH for the build
    source "$HOME/.cargo/env" || source "/root/.cargo/env" 2>/dev/null

    echo "Building the server binary (this may take a while)..."
    if cargo build --release --bin quicvpn-server; then
        cp "target/release/quicvpn-server" "${SERVER_BIN}"
        chmod +x "${SERVER_BIN}"
        echo -e "${GREEN}Server binary built and installed to ${SERVER_BIN}.${NC}"
    else
        echo -e "${RED}Build failed. Check build output for errors.${NC}"
        cd - &> /dev/null; rm -rf "${TMP_DIR}"; return 1
    fi

    cd - &> /dev/null
    rm -rf "${TMP_DIR}"
    echo "Temporary directory cleaned up."
    return 0
}

# Generate self-signed TLS certificate
generate_certificate() {
    echo -e "${BLUE}Generating self-signed TLS certificate...${NC}"
    local server_ip
    server_ip=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
    if [[ -z "$server_ip" ]]; then
        read -rp "Could not automatically detect IP. Enter server domain or IP address: " server_ip
        if [[ -z "$server_ip" ]]; then
            echo -e "${RED}Server IP/domain is required.${NC}"
            return 1
        fi
    else
         echo "Detected server IP: ${server_ip}"
    fi
    
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout "${SERVER_KEY}" -out "${SERVER_CERT}" \
        -subj "/CN=${server_ip}" \
        -addext "subjectAltName=IP:${server_ip}" # Use IP for SAN by default

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error generating certificate.${NC}"
        return 1
    fi

    chmod 600 "${SERVER_KEY}"
    chmod 644 "${SERVER_CERT}"
    echo -e "${GREEN}TLS certificate generated successfully.${NC}"
    return 0
}

# Create initial server configuration
configure_server() {
    echo -e "${BLUE}Configuring server...${NC}"
    local server_port ip_pool enable_game_opt

    prompt_input "Enter server UDP port" server_port "${DEFAULT_PORT}" validate_port
    prompt_input "Enter internal IP range (CIDR format)" ip_pool "${DEFAULT_IP_POOL}" validate_ip_pool
    
    if confirm_action "Enable gaming optimizations?"; then
        enable_game_opt="true"
    else
        enable_game_opt="false"
    fi

    # Create JSON configuration using jq for safety
    jq -n \
      --arg listen "0.0.0.0:${server_port}" \
      --arg cert "${SERVER_CERT}" \
      --arg key "${SERVER_KEY}" \
      --arg users "${USERS_FILE}" \
      --arg pool "${ip_pool}" \
      --argjson dns "${DEFAULT_DNS_SERVERS}" \
      --arg mtu "${DEFAULT_MTU}" \
      --arg keepalive "${DEFAULT_KEEPALIVE}" \
      --argjson gameopt "${enable_game_opt}" \
      --arg loglevel "${DEFAULT_LOG_LEVEL}" \
      --arg logfile "${LOG_FILE}" \
      '{
          listen_addr: $listen,
          cert_path: $cert,
          key_path: $key,
          users_file: $users,
          ip_pool: $pool,
          dns_servers: $dns,
          mtu: ($mtu | tonumber),
          keep_alive: ($keepalive | tonumber),
          enable_game_optimization: $gameopt,
          log_level: $loglevel,
          log_file: $logfile
      }' > "${SERVER_CONFIG_FILE}"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error creating server configuration file.${NC}"
        return 1
    fi

    # Create empty users file if it doesn't exist
    if [[ ! -f "${USERS_FILE}" ]]; then
        echo '{"users": []}' > "${USERS_FILE}"
    fi

    chmod 600 "${SERVER_CONFIG_FILE}" "${USERS_FILE}"
    touch "${LOG_FILE}"
    chown nobody:nogroup "${LOG_FILE}" 2>/dev/null # Attempt to set ownership, ignore errors
    chmod 640 "${LOG_FILE}"

    echo -e "${GREEN}Server configuration saved to ${SERVER_CONFIG_FILE}.${NC}"
    return 0
}

# Enable IP Forwarding
enable_ip_forwarding() {
    echo -e "${BLUE}Enabling IP Forwarding...${NC}"
    local sysctl_conf="/etc/sysctl.d/99-quicvpn-forward.conf"
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf /etc/sysctl.d/*.conf; then
        echo 'net.ipv4.ip_forward=1' > "${sysctl_conf}"
        sysctl -p "${sysctl_conf}"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Failed to apply sysctl settings.${NC}"
            return 1
        fi
        echo -e "${GREEN}IP Forwarding enabled.${NC}"
    else
        echo -e "${YELLOW}IP Forwarding already enabled.${NC}"
    fi
    return 0
}

# Setup firewall rules
setup_firewall() {
    echo -e "${BLUE}Setting up firewall rules...${NC}"
    local port ip_pool iface

    # Get config values safely using jq
    port=$(jq -r '.listen_addr | split(":")[1]' "${SERVER_CONFIG_FILE}" 2>/dev/null)
    ip_pool=$(jq -r '.ip_pool' "${SERVER_CONFIG_FILE}" 2>/dev/null)
    
    # Try to detect the default interface
    iface=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
    if [[ -z "$iface" ]]; then
        echo -e "${YELLOW}Could not detect default network interface. Assuming eth0.${NC}"
        iface="eth0"
    else
        echo "Detected default network interface: ${iface}"
    fi


    if [[ -z "$port" ]] || [[ -z "$ip_pool" ]]; then
        echo -e "${RED}Error reading port or IP pool from config file.${NC}"
        return 1
    fi

    echo "Allowing UDP port ${port}..."
    iptables -C INPUT -p udp --dport "${port}" -j ACCEPT 2>/dev/null || iptables -I INPUT -p udp --dport "${port}" -j ACCEPT

    echo "Allowing forwarding for VPN subnet ${ip_pool}..."
    iptables -C FORWARD -s "${ip_pool}" -j ACCEPT 2>/dev/null || iptables -I FORWARD -s "${ip_pool}" -j ACCEPT
    iptables -C FORWARD -d "${ip_pool}" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -I FORWARD -d "${ip_pool}" -m state --state RELATED,ESTABLISHED -j ACCEPT

    echo "Setting up NAT masquerade rule for interface ${iface}..."
    iptables -t nat -C POSTROUTING -s "${ip_pool}" -o "${iface}" -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s "${ip_pool}" -o "${iface}" -j MASQUERADE

    # Save rules
    if command -v netfilter-persistent >/dev/null; then
        echo "Saving rules with netfilter-persistent..."
        netfilter-persistent save
    elif command -v iptables-save >/dev/null && [[ -f /etc/sysconfig/iptables ]]; then
        echo "Saving rules to /etc/sysconfig/iptables..."
        iptables-save > /etc/sysconfig/iptables
    else
        echo -e "${YELLOW}Could not automatically persist iptables rules. Please configure manually.${NC}"
    fi

    echo -e "${GREEN}Firewall rules applied.${NC}"
    return 0
}

# Install systemd service file
install_service() {
     echo -e "${BLUE}Installing systemd service...${NC}"
     cat > "/etc/systemd/system/${QUICVPN_SERVICE}" << EOF
[Unit]
Description=QUIC VPN Server
After=network.target network-online.target
Requires=network-online.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=${SERVER_BIN} --config ${SERVER_CONFIG_FILE}
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536
# Add security hardening options if desired
# CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
# AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
# NoNewPrivileges=true
# ProtectSystem=strict
# ProtectHome=true
# PrivateTmp=true
# PrivateDevices=true
# ProtectHostname=true
# ProtectClock=true
# ProtectKernelTunables=true
# ProtectKernelModules=true
# ProtectKernelLogs=true
# ProtectControlGroups=true
# RestrictAddressFamilies=AF_INET AF_INET6
# RestrictRealtime=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    echo -e "${GREEN}Systemd service file created/updated.${NC}"
    return 0
}

# --- Main Actions ---

# Install Server
install_server() {
    print_banner
    echo -e "${YELLOW}Starting QUIC VPN Server Installation...${NC}"

    if [[ -f "${SERVER_CONFIG_FILE}" ]]; then
        if ! confirm_action "QUIC VPN seems already installed. Reinstall (will overwrite config)?"; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            return
        fi
        # Stop server before reinstalling
        stop_server_action > /dev/null 2>&1
    fi

    if ! install_dependencies; then exit 1; fi
    if ! download_and_install_binary; then exit 1; fi
    
    mkdir -p "${SERVER_CONFIG_DIR}" "${CLIENTS_DIR}"
    
    if ! generate_certificate; then exit 1; fi
    if ! configure_server; then exit 1; fi
    if ! enable_ip_forwarding; then exit 1; fi
    if ! setup_firewall; then exit 1; fi
    if ! install_service; then exit 1; fi

    echo -e "${BLUE}Enabling and starting QUIC VPN service...${NC}"
    systemctl enable "${QUICVPN_SERVICE}"
    systemctl start "${QUICVPN_SERVICE}"

    if systemctl is-active --quiet "${QUICVPN_SERVICE}"; then
        echo -e "${GREEN}QUIC VPN Server installed and started successfully!${NC}"
        echo -e "${YELLOW}Remember to add users via the User Management menu.${NC}"
    else
        echo -e "${RED}Installation complete, but failed to start the service.${NC}"
        echo -e "${YELLOW}Check logs: journalctl -u ${QUICVPN_SERVICE} or cat ${LOG_FILE}${NC}"
    fi
    pause_and_return
}

# Uninstall Server
uninstall_server() {
    print_banner
    echo -e "${YELLOW}Uninstalling QUIC VPN Server...${NC}"

    if ! confirm_action "ARE YOU SURE? This will stop the server, remove configs, users, certs, binary, and firewall rules."; then
        echo -e "${YELLOW}Uninstallation cancelled.${NC}"
        return
    fi

    echo -e "${BLUE}Stopping and disabling service...${NC}"
    systemctl stop "${QUICVPN_SERVICE}" 2>/dev/null
    systemctl disable "${QUICVPN_SERVICE}" 2>/dev/null

    echo -e "${BLUE}Removing service file...${NC}"
    rm -f "/etc/systemd/system/${QUICVPN_SERVICE}"
    systemctl daemon-reload

    echo -e "${BLUE}Removing firewall rules...${NC}"
    if [[ -f "${SERVER_CONFIG_FILE}" ]]; then
        local port ip_pool iface
        port=$(jq -r '.listen_addr | split(":")[1]' "${SERVER_CONFIG_FILE}" 2>/dev/null)
        ip_pool=$(jq -r '.ip_pool' "${SERVER_CONFIG_FILE}" 2>/dev/null)
        iface=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
         if [[ -z "$iface" ]]; then iface="eth0"; fi # Fallback

        if [[ -n "$port" ]]; then
            iptables -D INPUT -p udp --dport "${port}" -j ACCEPT 2>/dev/null
        fi
        if [[ -n "$ip_pool" ]]; then
             iptables -D FORWARD -s "${ip_pool}" -j ACCEPT 2>/dev/null
             iptables -D FORWARD -d "${ip_pool}" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null
             iptables -t nat -D POSTROUTING -s "${ip_pool}" -o "${iface}" -j MASQUERADE 2>/dev/null
        fi
        # Save rules after removal
        if command -v netfilter-persistent >/dev/null; then
            netfilter-persistent save 2>/dev/null
        elif command -v iptables-save >/dev/null && [[ -f /etc/sysconfig/iptables ]]; then
            iptables-save > /etc/sysconfig/iptables 2>/dev/null
        fi
    fi

    echo -e "${BLUE}Removing IP forwarding rule...${NC}"
    rm -f "/etc/sysctl.d/99-quicvpn-forward.conf"
    # Attempt to disable forwarding immediately (might require reboot otherwise)
    sysctl -w net.ipv4.ip_forward=0 >/dev/null 2>&1 

    echo -e "${BLUE}Removing binary...${NC}"
    rm -f "${SERVER_BIN}"

    echo -e "${BLUE}Removing configuration directory...${NC}"
    rm -rf "${SERVER_CONFIG_DIR}"

    echo -e "${BLUE}Removing log file...${NC}"
    rm -f "${LOG_FILE}"

    echo -e "${GREEN}QUIC VPN Server uninstalled successfully.${NC}"
    pause_and_return
}

# Add User
add_user() {
    print_banner
    echo -e "${YELLOW}Add New User${NC}"
    check_server_installed || return

    local username password user_id
    read -rp "Enter username: " username
    if [[ -z "$username" ]]; then
        echo -e "${RED}Username cannot be empty.${NC}"; pause_and_return; return
    fi

    # Check if user exists
    if jq -e --arg user "${username}" '.users[] | select(.username == $user)' "${USERS_FILE}" > /dev/null; then
        echo -e "${RED}Username '${username}' already exists.${NC}"; pause_and_return; return
    fi

    # Generate password and ID
    password=$(openssl rand -hex 12)
    user_id=$(cat /proc/sys/kernel/random/uuid)

    # Add user using jq
    jq --arg user "${username}" \
       --arg pass "${password}" \
       --arg id "${user_id}" \
       '.users += [{"username": $user, "password": $pass, "user_id": $id, "enabled": true}]' \
       "${USERS_FILE}" > "${USERS_FILE}.tmp" && mv "${USERS_FILE}.tmp" "${USERS_FILE}"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error updating users file.${NC}"; pause_and_return; return
    fi

    echo -e "${GREEN}User '${username}' added successfully.${NC}"
    echo -e "Password: ${YELLOW}${password}${NC}"
    echo -e "User ID: ${BLUE}${user_id}${NC}"

    if confirm_action "Generate client config file now?"; then
        generate_client_config_for_user "${username}" "${password}"
    fi
    
    # Reload server to apply changes (optional, depends on server implementation)
    # echo -e "${BLUE}Reloading server configuration...${NC}"
    # restart_server_action # Or maybe just send SIGHUP if server supports it

    pause_and_return
}

# Remove User
remove_user() {
    print_banner
    echo -e "${YELLOW}Remove User${NC}"
    check_server_installed || return

    list_users_simple # Show users to select from
    
    read -rp "Enter username to remove: " username
     if [[ -z "$username" ]]; then
        echo -e "${RED}Username cannot be empty.${NC}"; pause_and_return; return
    fi

    # Check if user exists before attempting removal
    if ! jq -e --arg user "${username}" '.users[] | select(.username == $user)' "${USERS_FILE}" > /dev/null; then
        echo -e "${RED}User '${username}' not found.${NC}"; pause_and_return; return
    fi
    
    if ! confirm_action "Are you sure you want to remove user '${username}'?"; then
         echo -e "${YELLOW}Removal cancelled.${NC}"; pause_and_return; return
    fi

    # Remove user using jq
    jq --arg user "${username}" 'del(.users[] | select(.username == $user))' "${USERS_FILE}" > "${USERS_FILE}.tmp" && mv "${USERS_FILE}.tmp" "${USERS_FILE}"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error updating users file.${NC}"; pause_and_return; return
    fi

    # Remove client config file if exists
    local client_config_file="${CLIENTS_DIR}/${username}.json"
    if [[ -f "$client_config_file" ]]; then
        rm -f "$client_config_file"
        echo "Removed client config file: ${client_config_file}"
    fi

    echo -e "${GREEN}User '${username}' removed successfully.${NC}"
    
    # Reload server config (optional)
    # restart_server_action 

    pause_and_return
}

# List Users
list_users() {
    print_banner
    echo -e "${YELLOW}User List${NC}"
    check_server_installed || return

    if ! jq -e '.users | length > 0' "${USERS_FILE}" > /dev/null; then
         echo "No users found."
         pause_and_return; return
    fi

    echo "------------------------------------------"
    jq -r '.users[] | "Username: \(.username)\nStatus:   \(if .enabled then "Enabled" else "Disabled" end)\nUser ID:  \(.user_id)\n------------------------------------------"' "${USERS_FILE}"
    pause_and_return
}

# List users (simple format)
list_users_simple() {
     check_server_installed || return 1
     echo "Available users:"
     jq -r '.users[] | .username' "${USERS_FILE}" || echo "(No users found)"
     echo "---"
}

# Generate Client Config file
generate_client_config_action() {
    print_banner
    echo -e "${YELLOW}Generate Client Configuration${NC}"
    check_server_installed || return

    list_users_simple || return # Show users
    
    local username password
    read -rp "Enter username to generate config for: " username
    if [[ -z "$username" ]]; then
        echo -e "${RED}Username cannot be empty.${NC}"; pause_and_return; return
    fi

    # Get password for the user
    password=$(jq -r --arg user "${username}" '.users[] | select(.username == $user) | .password // empty' "${USERS_FILE}")

    if [[ -z "$password" ]]; then
        echo -e "${RED}User '${username}' not found or has no password.${NC}"; pause_and_return; return
    fi

    generate_client_config_for_user "${username}" "${password}"
    pause_and_return
}

# Helper to generate the actual config file
generate_client_config_for_user() {
    local username="$1"
    local password="$2"
    
    local server_ip server_port allow_insecure game_opt client_config_file
    
    server_ip=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || jq -r '.listen_addr | split(":")[0]' "${SERVER_CONFIG_FILE}")
    server_port=$(jq -r '.listen_addr | split(":")[1]' "${SERVER_CONFIG_FILE}")
    game_opt=$(jq -r '.enable_game_optimization' "${SERVER_CONFIG_FILE}") # Get server setting

    # Assume self-signed certs require insecure for client
    allow_insecure="true" 
    
    client_config_file="${CLIENTS_DIR}/${username}.json"

    mkdir -p "${CLIENTS_DIR}" # Ensure directory exists

    # Create client JSON config
     jq -n \
      --arg server "${server_ip}:${server_port}" \
      --arg user "${username}" \
      --arg pass "${password}" \
      --argjson insecure "${allow_insecure}" \
      --argjson dns "${DEFAULT_DNS_SERVERS}" \
      --arg mtu "${DEFAULT_MTU}" \
      --argjson autoreconnect "true" \
      --argjson gameopt "${game_opt}" \
      --arg loglevel "${DEFAULT_LOG_LEVEL}" \
      '{
          server_addr: $server,
          username: $user,
          password: $pass,
          allow_insecure: $insecure,
          dns_servers: $dns,
          mtu: ($mtu | tonumber),
          auto_reconnect: $autoreconnect,
          gaming_optimization: $gameopt,
          log_level: $loglevel
      }' > "${client_config_file}"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error creating client configuration file.${NC}"
        return 1
    fi

    chmod 600 "${client_config_file}"
    echo -e "${GREEN}Client config file for '${username}' created successfully:${NC}"
    echo "${client_config_file}"
    echo -e "${YELLOW}You can now transfer this file to the client machine.${NC}"
    return 0
}


# --- Server Management Actions ---

# Start Server
start_server_action() {
    echo -e "${BLUE}Starting QUIC VPN Server...${NC}"
    if systemctl start "${QUICVPN_SERVICE}"; then
        sleep 1 # Give it a moment to start
        if systemctl is-active --quiet "${QUICVPN_SERVICE}"; then
            echo -e "${GREEN}Server started successfully.${NC}"
        else
             echo -e "${RED}Server failed to start. Check logs.${NC}"
        fi
    else
        echo -e "${RED}Failed to issue start command.${NC}"
    fi
    pause_and_return
}

# Stop Server
stop_server_action() {
    echo -e "${BLUE}Stopping QUIC VPN Server...${NC}"
    if systemctl stop "${QUICVPN_SERVICE}"; then
        sleep 1
        if ! systemctl is-active --quiet "${QUICVPN_SERVICE}"; then
            echo -e "${GREEN}Server stopped successfully.${NC}"
        else
            echo -e "${RED}Server may not have stopped cleanly.${NC}"
        fi
    else
        echo -e "${RED}Failed to issue stop command.${NC}"
    fi
    pause_and_return
}

# Restart Server
restart_server_action() {
    echo -e "${BLUE}Restarting QUIC VPN Server...${NC}"
    if systemctl restart "${QUICVPN_SERVICE}"; then
        sleep 1
        if systemctl is-active --quiet "${QUICVPN_SERVICE}"; then
            echo -e "${GREEN}Server restarted successfully.${NC}"
        else
            echo -e "${RED}Server failed to restart properly. Check logs.${NC}"
        fi
    else
        echo -e "${RED}Failed to issue restart command.${NC}"
    fi
    pause_and_return
}

# View Logs
view_logs_action() {
    print_banner
    echo -e "${YELLOW}Showing last 50 lines of server logs...${NC}"
    if command -v journalctl >/dev/null && systemctl list-units --full -all | grep -q "${QUICVPN_SERVICE}"; then
         journalctl -u "${QUICVPN_SERVICE}" -n 50 --no-pager --output cat
    elif [[ -f "${LOG_FILE}" ]]; then
         tail -n 50 "${LOG_FILE}"
    else
        echo -e "${RED}Could not find logs via journalctl or ${LOG_FILE}.${NC}"
    fi
    pause_and_return
}

# Show Status
show_status_action() {
    print_banner
    echo -e "${YELLOW}QUIC VPN Server Status${NC}"
    check_server_installed || return

    echo -e "\n${BLUE}Service Status:${NC}"
    systemctl status "${QUICVPN_SERVICE}" --no-pager | grep -E 'Active:|Loaded:|^\s*Main PID:'
    
    echo -e "\n${BLUE}Configuration:${NC}"
    echo "Config Dir:  ${SERVER_CONFIG_DIR}"
    echo "Config File: ${SERVER_CONFIG_FILE}"
    echo "Users File:  ${USERS_FILE}"
    echo "Log File:    ${LOG_FILE}"
    if jq -e . "${SERVER_CONFIG_FILE}" > /dev/null 2>&1; then
         echo "Listen Addr: $(jq -r '.listen_addr // "N/A"' ${SERVER_CONFIG_FILE})"
         echo "IP Pool:     $(jq -r '.ip_pool // "N/A"' ${SERVER_CONFIG_FILE})"
         echo "Gaming Opt:  $(jq -r '.enable_game_optimization // "N/A"' ${SERVER_CONFIG_FILE})"
    else
        echo -e "${RED}Server config file is invalid JSON or unreadable.${NC}"
    fi


    echo -e "\n${BLUE}Network:${NC}"
    local server_ip
    server_ip=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "N/A")
    echo "Public IP:   ${server_ip}"
    echo "IP Forward:  $(cat /proc/sys/net/ipv4/ip_forward)" # 0 or 1

    echo -e "\n${BLUE}Users:${NC}"
    if jq -e . "${USERS_FILE}" > /dev/null 2>&1; then
        local user_count
        user_count=$(jq '.users | length' "${USERS_FILE}")
        echo "Total Users: ${user_count}"
    else
        echo -e "${RED}Users file is invalid JSON or unreadable.${NC}"
    fi
    
    # Add more status checks if the server provides an API or status command

    pause_and_return
}

# --- Menu Functions ---

# Check if server files exist
check_server_installed() {
    if [[ ! -f "${SERVER_CONFIG_FILE}" ]] || [[ ! -f "${USERS_FILE}" ]]; then
        echo -e "${RED}Error: QUIC VPN server configuration not found.${NC}"
        echo "Please run the installation (Option 1) first."
        pause_and_return
        return 1
    fi
    return 0
}

# Pause script and wait for user
pause_and_return() {
  echo ""
  read -n 1 -s -r -p "Press any key to return to the menu..."
  echo ""
}

# Main Menu
main_menu() {
    local choice
    while true; do
        print_banner
        echo -e "${YELLOW}Main Menu:${NC}"
        echo "1) Install QUIC VPN Server"
        echo "2) User Management"
        echo "3) Server Management"
        echo "4) View Status"
        echo "5) Uninstall QUIC VPN"
        echo "6) Exit"
        echo ""
        read_choice "Enter your choice" "123456" choice

        case "$choice" in
            1) install_server ;;
            2) user_menu ;;
            3) server_menu ;;
            4) show_status_action ;;
            5) uninstall_server ;;
            6) echo "Exiting."; exit 0 ;;
        esac
    done
}

# User Management Menu
user_menu() {
    local choice
    while true; do
        print_banner
        echo -e "${YELLOW}User Management:${NC}"
        echo "1) Add User"
        echo "2) Remove User"
        echo "3) List Users"
        echo "4) Generate Client Config"
        echo "5) Back to Main Menu"
        echo ""
        read_choice "Enter your choice" "12345" choice

        case "$choice" in
            1) add_user ;;
            2) remove_user ;;
            3) list_users ;;
            4) generate_client_config_action ;;
            5) break ;; # Exit user menu loop
        esac
    done
}

# Server Management Menu
server_menu() {
    local choice
    while true; do
        print_banner
        echo -e "${YELLOW}Server Management:${NC}"
        echo "1) Start Server"
        echo "2) Stop Server"
        echo "3) Restart Server"
        echo "4) View Logs"
        echo "5) Back to Main Menu"
        echo ""
        read_choice "Enter your choice" "12345" choice

        case "$choice" in
            1) start_server_action ;;
            2) stop_server_action ;;
            3) restart_server_action ;;
            4) view_logs_action ;;
            5) break ;; # Exit server menu loop
        esac
    done
}


# --- Script Entry Point ---
check_root
main_menu 