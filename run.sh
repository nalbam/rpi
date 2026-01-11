#!/bin/bash

set -euo pipefail

SHELL_DIR=$(dirname "$0")
PACKAGE_DIR="${SHELL_DIR}/package"
TEMP_DIR=/tmp

USER=$(whoami)

# Check if tput is available for colored output
if command -v tput >/dev/null 2>&1; then
  TPUT=true
else
  TPUT=false
fi

# Print separator bar
_bar() {
  _echo "================================================================================"
}

# Print colored message
# Usage: _echo "message" [color_code]
_echo() {
  if [ "${TPUT}" = "true" ] && [ -n "${2:-}" ]; then
    echo -e "$(tput setaf "$2")$1$(tput sgr0)"
  else
    echo -e "$1"
  fi
}

# Read user input with optional color
# Usage: _read "prompt"
_read() {
  if [ "${TPUT}" = "true" ]; then
    read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
  else
    read -p "$1" ANSWER
  fi
}

# Print success message and exit
_success() {
  _echo "+ $*" 2
  exit 0
}

# Print error message and exit
_error() {
  _echo "- $*" 1
  exit 1
}

################################################################################

# Check OS version (requires Bookworm/Debian 12+)
check_os_version() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    VERSION_MAJOR=$(echo "${VERSION_ID}" | cut -d. -f1)
    if [ "${VERSION_MAJOR}" -lt "12" ]; then
      _error "This script requires Raspberry Pi OS Bookworm (Debian 12) or later. Current: ${PRETTY_NAME}"
    fi
    _echo "OS Version: ${PRETTY_NAME}" 6
  else
    _echo "Warning: Cannot verify OS version. This script requires Raspberry Pi OS Bookworm (Debian 12)+" 3
  fi
}

################################################################################

# Display usage information
usage() {
  echo " Usage: ${0} {cmd}"
  _bar
  echo
  echo "${0} init        [Install basic packages]"
  echo "${0} auto        [Run init automatically]"
  echo "${0} update      [Update repository]"
  echo "${0} upgrade     [Upgrade system packages]"
  echo "${0} node [VER]  [Install Node.js (default: 24)]"
  echo "${0} nginx       [Manage Nginx web server (init|add|ls|rm|...)]"
  echo
  _bar
}

# Run init automatically with OS version check
auto() {
  check_os_version
  init
}

# Update repository with git pull
update() {
  pushd "${SHELL_DIR}" > /dev/null
  git pull
  popd > /dev/null
}

# Upgrade system packages
upgrade() {
  sudo apt update
  sudo apt upgrade -y
  sudo apt clean all
  sudo apt autoremove -y
}

# Install basic packages and update system
# Requires: Raspberry Pi OS Bookworm (Debian 12+)
init() {
  _bar
  _echo "Installing basic packages..." 4
  _bar

  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y curl wget unzip vim jq git
  sudo apt clean all
  sudo apt autoremove -y

  _bar
  _success "Basic packages installed successfully!"
}

# Install Node.js with specified version
# Usage: node [version]
# Supported versions: 20, 22, 24
# Default: 24
node() {
  VERSION="${1:-24}"

  # Validate version
  if [[ ! "${VERSION}" =~ ^(20|22|24)$ ]]; then
    _error "Unsupported Node.js version: ${VERSION}. Supported versions: 20, 22, 24"
  fi

  _bar
  _echo "Installing Node.js ${VERSION}..." 4
  _bar

  # Download and verify before executing
  SETUP_SCRIPT="${TEMP_DIR}/nodesource_setup.sh"
  curl -fsSL "https://deb.nodesource.com/setup_${VERSION}.x" -o "${SETUP_SCRIPT}"

  # Execute with bash
  sudo bash "${SETUP_SCRIPT}"
  sudo apt install -y nodejs

  rm -f "${SETUP_SCRIPT}"

  _bar
  node -v
  npm -v
  _bar
}

# Install and configure Nginx web server with Certbot
# Enables automatic SSL certificate renewal
nginx_init() {
  _bar
  _echo "Installing nginx and certbot..." 4
  _bar

  # Install nginx and certbot
  sudo apt update
  sudo apt install -y nginx certbot python3-certbot-nginx

  # Enable and start nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx

  # Setup certbot auto-renewal
  _echo "Setting up certbot auto-renewal..." 2
  sudo systemctl enable certbot.timer
  sudo systemctl start certbot.timer

  _bar
  _success "Nginx and certbot installed successfully!"
}

# Add reverse proxy configuration for a domain
# Usage: nginx_add <domain> <port>
# Automatically configures SSL with Let's Encrypt
nginx_add() {
  DOMAIN="${1:-}"
  PORT="${2:-}"

  if [ -z "${DOMAIN}" ] || [ -z "${PORT}" ]; then
    _error "Usage: ${0} nginx add <domain> <port>"
  fi

  # Validate domain format
  if ! [[ "${DOMAIN}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    _error "Invalid domain format: ${DOMAIN}"
  fi

  # Validate port number
  if ! [[ "${PORT}" =~ ^[0-9]+$ ]] || [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
    _error "Invalid port number: ${PORT}"
  fi

  SITE_AVAILABLE="/etc/nginx/sites-available/${DOMAIN}"
  SITE_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

  # Check if site already exists
  if [ -f "${SITE_AVAILABLE}" ]; then
    _error "Site configuration already exists: ${DOMAIN}"
  fi

  _bar
  _echo "Creating nginx configuration for ${DOMAIN} -> localhost:${PORT}..." 4
  _bar

  # Create nginx configuration from template
  sudo cp "${PACKAGE_DIR}/nginx-proxy.conf" "${SITE_AVAILABLE}"
  sudo sed -i "s/DOMAIN/${DOMAIN}/g" "${SITE_AVAILABLE}"
  sudo sed -i "s/PORT/${PORT}/g" "${SITE_AVAILABLE}"

  # Enable site
  sudo ln -sf "${SITE_AVAILABLE}" "${SITE_ENABLED}"

  # Test nginx configuration
  if ! sudo nginx -t; then
    sudo rm -f "${SITE_AVAILABLE}" "${SITE_ENABLED}"
    _error "Nginx configuration test failed. Configuration removed."
  fi

  # Reload nginx
  sudo systemctl reload nginx

  _echo "Site ${DOMAIN} created successfully!" 2
  _echo ""

  # Ask for SSL certificate
  _read "Do you want to setup SSL certificate with Let's Encrypt? (y/N): "
  if [[ "${ANSWER}" =~ ^[Yy]$ ]]; then
    _echo "Setting up SSL certificate..." 4
    _echo "Make sure your domain ${DOMAIN} points to this server's IP address." 3

    # Ask for email
    _read "Enter email for SSL certificate (default: admin@${DOMAIN}): "
    EMAIL="${ANSWER:-admin@${DOMAIN}}"

    sleep 2

    # Run certbot
    if sudo certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos --redirect --email "${EMAIL}" 2>/dev/null; then
      _bar
      _success "SSL certificate installed successfully for ${DOMAIN}!"
    else
      _echo "SSL certificate installation failed. You can try manually later with:" 3
      _echo "  sudo certbot --nginx -d ${DOMAIN}" 3
      _echo ""
      _echo "Site is still accessible via HTTP." 2
    fi
  else
    _bar
    _success "Site ${DOMAIN} is now accessible via HTTP (port 80)."
  fi
}

# List all configured Nginx sites
# Shows domain, port, and SSL status
nginx_list() {
  _bar
  _echo "Nginx sites configuration:" 4
  _bar

  if [ ! -d "/etc/nginx/sites-enabled" ]; then
    _echo "Nginx is not installed or sites-enabled directory not found." 1
    return
  fi

  # List enabled sites
  SITES=$(find /etc/nginx/sites-enabled -type l -o -type f 2>/dev/null | grep -v default | sort)

  if [ -z "${SITES}" ]; then
    _echo "No sites configured." 3
    return
  fi

  _echo ""
  printf "%-30s %-10s %-10s\n" "DOMAIN" "PORT" "SSL"
  echo "--------------------------------------------------------------------------------"

  for SITE_PATH in ${SITES}; do
    SITE_NAME=$(basename "${SITE_PATH}")

    # Extract port from configuration (using POSIX-compliant grep)
    if [ -f "${SITE_PATH}" ]; then
      PORT=$(grep -o 'proxy_pass.*:[0-9]*' "${SITE_PATH}" | grep -o '[0-9]*$' | head -1)
      SSL_STATUS=$(grep -q "listen 443 ssl" "${SITE_PATH}" && echo "✓ Yes" || echo "✗ No")

      if [ -n "${PORT}" ]; then
        printf "%-30s %-10s %-10s\n" "${SITE_NAME}" "${PORT}" "${SSL_STATUS}"
      else
        printf "%-30s %-10s %-10s\n" "${SITE_NAME}" "N/A" "${SSL_STATUS}"
      fi
    fi
  done

  _echo ""
  _bar
}

# Remove site configuration and SSL certificate
# Usage: nginx_remove <domain>
nginx_remove() {
  DOMAIN="${1:-}"

  if [ -z "${DOMAIN}" ]; then
    _error "Usage: ${0} nginx rm <domain>"
  fi

  SITE_AVAILABLE="/etc/nginx/sites-available/${DOMAIN}"
  SITE_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

  if [ ! -f "${SITE_AVAILABLE}" ]; then
    _error "Site configuration not found: ${DOMAIN}"
  fi

  _bar
  _echo "Removing nginx configuration for ${DOMAIN}..." 4
  _bar

  # Confirm removal
  _read "Are you sure you want to remove ${DOMAIN}? (y/N): "
  if [[ ! "${ANSWER}" =~ ^[Yy]$ ]]; then
    _echo "Cancelled." 3
    return
  fi

  # Remove SSL certificate if exists
  if sudo certbot certificates 2>/dev/null | grep -q "${DOMAIN}"; then
    _read "SSL certificate found. Remove it? (y/N): "
    if [[ "${ANSWER}" =~ ^[Yy]$ ]]; then
      sudo certbot delete --cert-name "${DOMAIN}" --non-interactive
      _echo "SSL certificate removed." 2
    fi
  fi

  # Remove nginx configuration
  sudo rm -f "${SITE_ENABLED}"
  sudo rm -f "${SITE_AVAILABLE}"

  # Reload nginx
  sudo nginx -t && sudo systemctl reload nginx

  _bar
  _success "Site ${DOMAIN} removed successfully!"
}

# Reload Nginx configuration
nginx_reload() {
  _bar
  _echo "Reloading nginx..." 4
  _bar

  if sudo nginx -t; then
    sudo systemctl reload nginx
    _bar
    _success "Nginx reloaded successfully!"
  else
    _error "Nginx configuration test failed. Please fix the errors."
  fi
}

# Test Nginx configuration
nginx_test() {
  _bar
  _echo "Testing nginx configuration..." 4
  _bar

  if sudo nginx -t; then
    _bar
    _success "Nginx configuration test passed!"
  else
    _error "Nginx configuration test failed!"
  fi
}

# Show Nginx service status
nginx_status() {
  _bar
  _echo "Nginx service status:" 4
  _bar
  _echo ""

  sudo systemctl status nginx --no-pager

  _echo ""
  _bar
}

# Enable a site
# Usage: nginx_enable <domain>
nginx_enable() {
  DOMAIN="${1:-}"

  if [ -z "${DOMAIN}" ]; then
    _error "Usage: ${0} nginx enable <domain>"
  fi

  SITE_AVAILABLE="/etc/nginx/sites-available/${DOMAIN}"
  SITE_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

  if [ ! -f "${SITE_AVAILABLE}" ]; then
    _error "Site configuration not found: ${DOMAIN}"
  fi

  if [ -L "${SITE_ENABLED}" ]; then
    _echo "Site ${DOMAIN} is already enabled." 3
    return
  fi

  sudo ln -sf "${SITE_AVAILABLE}" "${SITE_ENABLED}"
  sudo nginx -t && sudo systemctl reload nginx

  _success "Site ${DOMAIN} enabled!"
}

# Disable a site
# Usage: nginx_disable <domain>
nginx_disable() {
  DOMAIN="${1:-}"

  if [ -z "${DOMAIN}" ]; then
    _error "Usage: ${0} nginx disable <domain>"
  fi

  SITE_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

  if [ ! -L "${SITE_ENABLED}" ] && [ ! -f "${SITE_ENABLED}" ]; then
    _echo "Site ${DOMAIN} is already disabled." 3
    return
  fi

  sudo rm -f "${SITE_ENABLED}"
  sudo nginx -t && sudo systemctl reload nginx

  _success "Site ${DOMAIN} disabled!"
}

# View Nginx logs for a domain
# Usage: nginx_log <domain> [access|error]
# Default: access logs
nginx_log() {
  DOMAIN="${1:-}"
  LOG_TYPE="${2:-access}"

  if [ -z "${DOMAIN}" ]; then
    _error "Usage: ${0} nginx log <domain> [access|error]"
  fi

  # Validate log type
  if [ "${LOG_TYPE}" != "access" ] && [ "${LOG_TYPE}" != "error" ]; then
    _error "Invalid log type: ${LOG_TYPE}. Use 'access' or 'error'"
  fi

  if [ "${LOG_TYPE}" = "error" ]; then
    LOG_FILE="/var/log/nginx/${DOMAIN}.error.log"
  else
    LOG_FILE="/var/log/nginx/${DOMAIN}.access.log"
  fi

  if [ ! -f "${LOG_FILE}" ]; then
    LOG_FILE="/var/log/nginx/${LOG_TYPE}.log"
  fi

  _bar
  _echo "Nginx ${LOG_TYPE} log for ${DOMAIN}:" 4
  _bar
  _echo ""

  if [ -f "${LOG_FILE}" ]; then
    sudo tail -50 "${LOG_FILE}"
  else
    _echo "Log file not found: ${LOG_FILE}" 1
  fi

  _echo ""
  _bar
}

# Renew SSL certificates
nginx_ssl_renew() {
  _bar
  _echo "Renewing SSL certificates..." 4
  _bar

  sudo certbot renew

  _bar
  _success "SSL certificate renewal complete!"
}

# Nginx management commands
# Usage: nginx <subcommand> [args]
nginx() {
  SUBCMD="${1:-}"

  # Validate subcommand
  if [ -z "${SUBCMD}" ]; then
    _echo "Usage: ${0} nginx {init|add|ls|rm|reload|test|status|enable|disable|log|ssl-renew}" 1
    echo ""
    echo "Commands:"
    echo "  init                     - Install nginx and certbot"
    echo "  add <domain> <port>      - Add reverse proxy configuration"
    echo "  ls                       - List all configured sites"
    echo "  rm <domain>              - Remove site configuration"
    echo "  reload                   - Reload nginx configuration"
    echo "  test                     - Test nginx configuration"
    echo "  status                   - Show nginx service status"
    echo "  enable <domain>          - Enable site"
    echo "  disable <domain>         - Disable site"
    echo "  log <domain> [access|error] - View nginx logs"
    echo "  ssl-renew                - Renew SSL certificates"
    echo ""
    exit 1
  fi

  case ${SUBCMD} in
    init)
      nginx_init
      ;;
    add)
      nginx_add "${2:-}" "${3:-}"
      ;;
    ls|list)
      nginx_list
      ;;
    rm|remove)
      nginx_remove "${2:-}"
      ;;
    reload|restart)
      nginx_reload
      ;;
    test)
      nginx_test
      ;;
    status)
      nginx_status
      ;;
    enable)
      nginx_enable "${2:-}"
      ;;
    disable)
      nginx_disable "${2:-}"
      ;;
    log)
      nginx_log "${2:-}" "${3:-}"
      ;;
    ssl-renew)
      nginx_ssl_renew
      ;;
    *)
      _echo "Unknown nginx command: ${SUBCMD}" 1
      echo ""
      _echo "Usage: ${0} nginx {init|add|ls|rm|reload|test|status|enable|disable|log|ssl-renew}" 1
      echo ""
      echo "Commands:"
      echo "  init                     - Install nginx and certbot"
      echo "  add <domain> <port>      - Add reverse proxy configuration"
      echo "  ls                       - List all configured sites"
      echo "  rm <domain>              - Remove site configuration"
      echo "  reload                   - Reload nginx configuration"
      echo "  test                     - Test nginx configuration"
      echo "  status                   - Show nginx service status"
      echo "  enable <domain>          - Enable site"
      echo "  disable <domain>         - Disable site"
      echo "  log <domain> [access|error] - View nginx logs"
      echo "  ssl-renew                - Renew SSL certificates"
      echo ""
      exit 1
      ;;
  esac
}

################################################################################

CMD="${1:-}"
PARAM1="${2:-}"
PARAM2="${3:-}"

case ${CMD} in
auto)
  auto
  ;;
update)
  update
  ;;
upgrade)
  upgrade
  ;;
init)
  check_os_version
  init
  ;;
node | nodejs)
  node "${PARAM1}"
  ;;
nginx)
  shift
  nginx "$@"
  ;;
*)
  usage
  ;;
esac
