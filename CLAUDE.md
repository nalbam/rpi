# CLAUDE.md

This file serves as a guide for Claude Code (claude.ai/code) when working in this repository.

## Project Overview

Utility scripts for Raspberry Pi initialization and web server setup. Designed exclusively for **Raspberry Pi OS Bookworm (Debian 12)**.

## System Requirements

- **Raspberry Pi OS Bookworm (Debian 12) or later**
- Raspberry Pi 3/4/5

> ⚠️ **Important**: Legacy systems (Bullseye, Buster, etc.) are not supported.

## Quick Setup

```bash
git clone https://github.com/nalbam/rpi
cd rpi
./run.sh auto
```

The `auto` command installs basic packages.

## Core Features

### 1. System Initialization
- Install basic packages (curl, wget, unzip, vim, jq, git)
- System update and upgrade
- OS version check (Bookworm or later required)

### 2. Node.js Installation
- Version selection available (20, 22, 24)
- Uses nodesource repository
- Automatic installation and verification

### 3. Nginx Web Server Management
- Install Nginx and Certbot
- Automatic reverse proxy configuration
- Let's Encrypt SSL automatic issuance and renewal
- WebSocket support
- Domain management (add, remove, list, enable/disable)

## Main Commands

### Initialization
```bash
./run.sh init      # Install basic packages
./run.sh auto      # Run init automatically
./run.sh update    # Update repository with git pull
./run.sh upgrade   # Upgrade apt packages
```

### Node.js
```bash
./run.sh node      # Install Node.js 24 (default)
./run.sh node 20   # Install Node.js 20
./run.sh node 22   # Install Node.js 22
```

### Nginx
```bash
# Installation
./run.sh nginx init

# Add reverse proxy (with automatic SSL)
./run.sh nginx add example.com 3000
./run.sh nginx add api.example.com 8080

# Management
./run.sh nginx ls                  # List sites
./run.sh nginx rm example.com      # Remove site
./run.sh nginx reload              # Reload configuration
./run.sh nginx test                # Test configuration
./run.sh nginx status              # Show status
./run.sh nginx enable example.com  # Enable site
./run.sh nginx disable example.com # Disable site
./run.sh nginx log example.com     # View logs
./run.sh nginx ssl-renew           # Renew SSL certificates
```

## Architecture

### Core Components

**`run.sh`** - Main management script
- Enhanced safety with `set -euo pipefail`
- Input validation and error handling
- OS version check (Bookworm or later)

**`package/nginx-proxy.conf`** - Nginx reverse proxy template
- HTTP/1.1 support
- WebSocket support (Upgrade header)
- Automatic X-Forwarded-* header configuration
- Proxy cache bypass
- File upload size limit (100MB)
- Production timeout settings (60s)

## Project Structure

```
rpi/
├── run.sh                    # Main script
├── package/                  # Configuration templates
│   └── nginx-proxy.conf      # Nginx reverse proxy template
├── README.md                 # User documentation
├── CLAUDE.md                 # This file
└── LICENSE                   # MIT License
```

## Security and Quality

### Security
1. **Command injection defense**: Safe script execution
2. **Input validation**:
   - Domain format validation (RFC compliant)
   - Port range validation (1-65535)
   - Node.js version validation (20, 22, 24)
   - Log type validation (access, error)
3. **Script safety**: `set -euo pipefail` applied
4. **SSL automation**: Let's Encrypt certbot automatic renewal
5. **Safe deletion**: Confirmation prompts to prevent mistakes

### Error Handling
1. **Configuration validation**: Pre-check with nginx -t
2. **Rollback**: Automatic rollback on failure
3. **Clear error messages**: User-friendly error output
4. **Compatibility**: POSIX-compliant grep usage

## Code Patterns

### Bash Script Patterns

The `run.sh` script follows these patterns:

- **Safety**: Immediate termination on error with `set -euo pipefail`
- **Input validation**: Validation and quoting of all user inputs
- **Error handling**: Consistent error messages with `_error()` function
- **Template-based configuration**: Copy and modify configuration files from `package/`
- **Environment detection**: OS version check and validation

### Function Structure

```bash
# Utility functions
_bar()        # Print separator line
_echo()       # Colored output
_read()       # User input
_success()    # Success message and exit
_error()      # Error message and exit

# Main feature functions
check_os_version()  # Check OS version
init()              # System initialization
node()              # Node.js installation
nginx()             # Nginx management
```

## Bookworm (Debian 12) Changes

This version has been simplified for Bookworm only:

### Removed Features
- GPIO programming (gpio/ directory)
- Thermal camera (lepton/ directory)
- OpenCV/CCTV (cv2/ directory)
- Systemd services (systemd/ directory)
- WiFi/Sound/Screensaver/Kiosk configuration
- Docker installation

### Retained Core Features
- System initialization (init, update, upgrade)
- Node.js installation
- Nginx web server management

## Development Guidelines

Follow these principles when writing code:

1. **Security first**: Input validation, error handling, safe code execution
2. **Error handling**: Consider and handle all error scenarios
3. **Simplicity**: Keep only necessary features
4. **Documentation**: Clear explanations with comments and README
5. **Consistency**: Follow existing code patterns
6. **Compatibility**: POSIX standard compliance (use grep -o, avoid grep -P)
7. **User experience**: Confirmation prompts before critical operations

## Recent Improvements (2026-01-11)

### Bug Fixes
- Fixed nginx argument passing bug (using shift)
- Changed grep -P → grep -o (POSIX compatibility)

### Feature Improvements
- Added domain format validation
- Added Node.js version validation (20, 22, 24)
- Added log type validation (access, error)
- Added SSL email user input feature
- Added confirmation prompt when deleting domains
- Added production settings to nginx-proxy.conf (timeout, upload size)
- Added comments to all major functions
- Improved nginx subcommand validation

## Reference Documentation

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
- [Raspberry Pi OS Documentation](https://www.raspberrypi.com/documentation/computers/os.html)
- [Node.js Documentation](https://nodejs.org/en/docs/)

## License

MIT License
