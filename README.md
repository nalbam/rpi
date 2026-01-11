# Raspberry Pi Utilities

A collection of utility scripts for Raspberry Pi initialization and environment setup.

## Features

- 🚀 **Raspberry Pi OS Bookworm (Debian 12) Only**
- 🔧 **Simple Initialization** - Basic packages and development environment setup
- 🌐 **Nginx Web Server** - Reverse proxy with automatic SSL configuration
- 📦 **Node.js Installation** - Version selection available (20, 22, 24)
- 🛡️ **Enhanced Security** - Automatic Let's Encrypt SSL issuance and renewal

## System Requirements

- **Raspberry Pi OS Bookworm (Debian 12)** or later
- Raspberry Pi 3/4/5
- Python 3.11+
- lgpio library

> ⚠️ **Important**: This version is designed exclusively for Bookworm (Debian 12). Legacy systems (Bullseye and earlier) are not supported.

## Quick Start

```bash
git clone https://github.com/nalbam/rpi
cd rpi
./run.sh auto
```

## Main Commands

### System Setup

```bash
./run.sh init                      # Install basic packages
./run.sh auto                      # Run init automatically
./run.sh update                    # Update repository (git pull)
./run.sh upgrade                   # Upgrade system packages
```

### Development Environment

```bash
./run.sh node                      # Install Node.js 24 (default)
./run.sh node 20                   # Install Node.js 20
./run.sh node 22                   # Install Node.js 22
```

### Nginx Web Server

```bash
# Install Nginx and Certbot
./run.sh nginx init

# Add reverse proxy (with automatic SSL)
./run.sh nginx add example.com 3000
./run.sh nginx add api.example.com 8080

# List sites
./run.sh nginx ls

# Remove site
./run.sh nginx rm example.com

# Other commands
./run.sh nginx reload              # Reload configuration
./run.sh nginx test                # Test configuration
./run.sh nginx status              # Show status
./run.sh nginx enable example.com  # Enable site
./run.sh nginx disable example.com # Disable site
./run.sh nginx log example.com     # View logs
./run.sh nginx ssl-renew           # Renew SSL certificates
```

**Features:**
- Automatic reverse proxy configuration
- Let's Encrypt SSL automatic issuance and renewal (certbot)
- WebSocket support
- File upload size limit (100MB)
- Production timeout settings (60s)
- Domain and port validation
- Easy domain management

## Security Features

### Input Validation
- **Domain Validation**: Only RFC-compliant domain formats allowed
- **Port Validation**: Range check (1-65535)
- **Version Validation**: Only supported Node.js versions (20, 22, 24)

### Safe Deletion
- Confirmation prompt when deleting domains
- Separate confirmation for SSL certificates

## Troubleshooting

### Nginx Installation Failed

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

### SSL Certificate Issuance Failed

Verify that your domain points to this server's IP address:
```bash
nslookup example.com
ping example.com
```

Ensure ports 80 and 443 are open in your firewall.

### grep Compatibility Issues

This script uses POSIX-compliant grep, so it works on all Linux systems.

## License

MIT License

## Contributing

Issue reports and Pull Requests are welcome!

## Related Links

- [lgpio Documentation](https://github.com/joan2937/lg)
- [Raspberry Pi OS Documentation](https://www.raspberrypi.com/documentation/computers/os.html)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
