# QUIC VPN for Gaming

A scalable, high-performance VPN built with QUIC protocol, specifically optimized for gaming. This VPN solution features a Windows client and Linux server.

## Features

- **QUIC Protocol**: Built on top of UDP with modern congestion control algorithms
- **Gaming Optimized**: Low latency configuration for real-time gaming traffic
- **Scalable Architecture**: Designed to handle multiple concurrent connections
- **Windows Client**: Easy-to-use client with Windows Service support
- **Linux Server**: Efficient and lightweight server for various Linux distributions
- **TUN Interface**: Creates virtual network interfaces to route traffic
- **Strong Encryption**: Uses TLS 1.3 for secure connections
- **User Authentication**: Simple username/password authentication

## Components

- **Common**: Shared code between client and server
- **Client**: Windows client application
- **Server**: Linux server application

## Building from Source

### Prerequisites

- Rust 1.67+ with Cargo
- For Windows client: Windows 10/11 with administrator privileges
- For Linux server: Linux with kernel 3.17+ and root privileges

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/username/quicvpn.git
cd quicvpn

# Build the project
cargo build --release
```

## Server Setup (Linux)

1. Generate certificates and config:

```bash
./target/release/server --generate-cert
```

2. Edit the generated `config.json` file to customize:
   - Listen address
   - VPN subnet
   - User database path
   - MTU settings
   - Gaming optimization flags

3. Run the server:

```bash
sudo ./target/release/server --config config.json
```

## Client Setup (Windows)

1. Initialize client configuration:

```bash
./target/release/client.exe init --server your-server-ip:4433 --username your-username --password your-password --game-optimized
```

2. Connect to the VPN:

```bash
./target/release/client.exe connect
```

3. Install as a Windows service (optional):

```bash
./target/release/client.exe install
```

## Architecture

The VPN uses the QUIC protocol which provides:
- Stream multiplexing over a single connection
- Low latency connection establishment
- Improved congestion control
- Reliable packet delivery with minimal overhead
- Migration between network interfaces

The TUN device captures and injects IP packets, allowing the VPN to handle any IP-based protocol.

## Gaming Optimizations

- Reduced keepalive intervals
- Prioritization of real-time traffic
- Lower initial round-trip time estimation
- Fast recovery from packet loss
- Conservative congestion control

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Easy Installation

To quickly install QUIC VPN Server on your Linux system, run the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/Echo9009/Echo/main/scripts/easy_install_en.sh | sudo bash
```

This will download and run the installation script which will guide you through the setup process.

## Installation Features

The easy installation script provides:

- One-click server installation
- User management (add/remove users)
- Client configuration generation
- Server management (start/stop/restart)
- Status monitoring
- Easy uninstallation option

## Manual Installation

For manual installation instructions, please refer to the [server setup documentation](docs/04-server-setup.md).

## Client Setup

After installing the server and creating users, you can download client configuration files and set up clients as described in the [client setup documentation](docs/05-client-setup.md).

## Documentation

- [Server Setup](docs/04-server-setup.md)
- [Client Setup](docs/05-client-setup.md)
- [Gaming Optimizations](docs/07-gaming-optimizations.md)
- [Security](docs/08-security.md)
- [Troubleshooting](docs/09-troubleshooting.md)
- [Development](docs/10-development.md)
- [Appendix](docs/11-appendix.md) 