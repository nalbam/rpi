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

_bar() {
  _echo "================================================================================"
}

_echo() {
  if [ "${TPUT}" = "true" ] && [ -n "${2:-}" ]; then
    echo -e "$(tput setaf "$2")$1$(tput sgr0)"
  else
    echo -e "$1"
  fi
}

_read() {
  if [ "${TPUT}" = "true" ]; then
    read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
  else
    read -p "$1" ANSWER
  fi
}

_select_one() {
  echo

  IDX=0
  while read VAL; do
    IDX=$((IDX + 1))
    printf "%3s. %s\n" "${IDX}" "${VAL}"
  done <"${LIST}"

  CNT=$(wc -l < "${LIST}" | xargs)

  echo
  _read "Please select one. (1-${CNT}) : "

  SELECTED=
  if [ -z "${ANSWER}" ]; then
    return
  fi
  TEST='^[0-9]+$'
  if ! [[ ${ANSWER} =~ ${TEST} ]]; then
    return
  fi
  SELECTED=$(sed -n "${ANSWER}p" "${LIST}")
}

_result() {
  _echo "# $*" 4
}

_command() {
  _echo "$ $*" 3
}

_success() {
  _echo "+ $*" 2
  exit 0
}

_error() {
  _echo "- $*" 1
  exit 1
}

################################################################################

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

enable_interfaces() {
  _bar
  _echo "Enabling hardware interfaces (SPI, I2C, Camera)..." 4
  _bar

  # Enable SPI (for Lepton thermal camera)
  if command -v raspi-config >/dev/null; then
    sudo raspi-config nonint do_spi 0
    _echo "SPI enabled" 2

    # Enable I2C
    sudo raspi-config nonint do_i2c 0
    _echo "I2C enabled" 2

    # Enable Camera
    sudo raspi-config nonint do_camera 0
    _echo "Camera enabled" 2

    _bar
    _echo "Hardware interfaces enabled successfully!" 2
    _echo "Reboot required for changes to take effect" 3
    _bar

    _read "Reboot now? [y/N]: "
    if [ "${ANSWER}" == "y" ] || [ "${ANSWER}" == "Y" ]; then
      reboot_system
    fi
  else
    _error "raspi-config not found. Are you running on Raspberry Pi OS?"
  fi
}

################################################################################

usage() {
  echo " Usage: ${0} {cmd}"
  _bar
  echo
  echo "${0} init        [기본 패키지 설치]"
  echo "${0} auto        [init, aliases]"
  echo "${0} update      [저장소 업데이트]"
  echo "${0} upgrade     [시스템 패키지 업그레이드]"
  echo "${0} aliases     [쉘 별칭 설정]"
  echo "${0} interfaces  [하드웨어 인터페이스 활성화 (SPI, I2C, Camera)]"
  echo "${0} node [VER]  [Node.js 설치 (기본: 24)]"
  echo "${0} docker      [Docker 설치]"
  echo "${0} nginx       [Nginx 웹서버 관리 (init|add|ls|rm|...)]"
  echo "${0} wifi        [WiFi 설정 (NetworkManager)]"
  echo "${0} sound       [오디오 설정 (PulseAudio/PipeWire)]"
  echo "${0} screensaver [화면보호기 비활성화 (Wayfire)]"
  echo "${0} kiosk       [키오스크 모드 설정]"
  echo
  _bar
}

auto() {
  check_os_version
  init
  aliases
}

update() {
  pushd "${SHELL_DIR}" > /dev/null
  git pull
  popd > /dev/null
}

upgrade() {
  sudo apt update
  sudo apt upgrade -y
  sudo apt clean all
  sudo apt autoremove -y
}

init() {
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y curl wget unzip vim jq git
  sudo apt install -y fbi ibus ibus-hangul fonts-unfonts-core
  sudo apt install -y liblgpio-dev libgpiod-dev python3-lgpio python3-libgpiod python3-rpi-lgpio
  sudo apt clean all
  sudo apt autoremove -y

  # Add user to gpio group for hardware access
  if ! groups "${USER}" | grep -q gpio; then
    sudo usermod -aG gpio "${USER}"
    _echo "Added ${USER} to gpio group. Please reboot or re-login for changes to take effect!" 3
  fi
}

aliases() {
  TEMPLATE="${PACKAGE_DIR}/aliases.sh"
  TARGET="${HOME}/.bash_aliases"

  backup "${TARGET}"

  cp -f "${TEMPLATE}" "${TARGET}"

  _bar
  cat "${TARGET}"
  _bar
}

node() {
  VERSION="${1:-24}"

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

docker() {
  # Download and verify before executing
  DOCKER_SCRIPT="${TEMP_DIR}/get-docker.sh"
  curl -fsSL https://get.docker.com -o "${DOCKER_SCRIPT}"

  # Execute with sh
  sudo sh "${DOCKER_SCRIPT}"
  sudo usermod "${USER}" -aG docker

  rm -f "${DOCKER_SCRIPT}"

  _bar
  docker -v
  _bar
}

wifi() {
  SSID="${1:-}"
  PASS="${2:-}"

  if [ -z "${SSID}" ] || [ -z "${PASS}" ]; then
    _error "Usage: $0 wifi SSID PASSWORD"
  fi

  # NetworkManager only (Bookworm default)
  if ! systemctl is-active --quiet NetworkManager; then
    _error "NetworkManager is not running. Please install and start NetworkManager."
  fi

  _echo "Using NetworkManager..." 3

  # Delete existing connection if present
  nmcli connection delete "${SSID}" 2>/dev/null || true

  # Add new WiFi connection
  nmcli device wifi connect "${SSID}" password "${PASS}"

  _bar
  _echo "WiFi connected successfully" 2
  nmcli connection show "${SSID}"
  _bar
}

sound() {
  _bar
  _echo "Audio Configuration (PulseAudio/PipeWire)" 4
  _bar

  # Check for PulseAudio/PipeWire
  if ! command -v pactl >/dev/null; then
    _error "PulseAudio/PipeWire is not installed. Please install pipewire-pulse or pulseaudio."
  fi

  _echo "Available audio devices:" 3
  aplay -l

  _bar
  pactl list short sinks

  _bar
  _echo "To change default audio output:" 3
  _echo "  raspi-config -> System Options -> Audio" 6
  _echo "  Or use GUI: pavucontrol (install: sudo apt install pavucontrol)" 6
  _bar
  _echo "Test audio with: speaker-test -t wav -c 2" 6
  _bar
}

autostart() {
  # Create start.sh script
  TEMPLATE="${PACKAGE_DIR}/start.sh"
  TARGET="${HOME}/start.sh"

  cp -f "${TEMPLATE}" "${TARGET}"
  chmod 755 "${TARGET}"

  _bar
  _echo "Start script created: ${TARGET}" 2
  cat "${TARGET}"
  _bar

  # XDG autostart (Wayfire, GNOME, modern desktops)
  mkdir -p "${HOME}/.config/autostart"
  DESKTOP_FILE="${HOME}/.config/autostart/rpi-startup.desktop"

  cat >"${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=RPI Startup
Exec=${HOME}/start.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

  _bar
  _echo "XDG autostart configured: ${DESKTOP_FILE}" 2
  cat "${DESKTOP_FILE}"
  _bar
}

kiosk() {
  CMD="${1:-}"

  if [ "${CMD}" == "stop" ]; then
    killall chromium-browser 2>/dev/null || killall chromium 2>/dev/null || true
    rm -f "${HOME}/.config/rpi-kiosk"
    _echo "Kiosk mode stopped" 2
    return
  fi

  # Install required packages
  command -v unclutter >/dev/null || sudo apt install -y unclutter
  command -v matchbox-window-manager >/dev/null || sudo apt install -y matchbox-window-manager

  # URL configuration
  TARGET="${HOME}/.config/rpi-kiosk"
  LIST="${HOME}/.config/rpi-kiosk-list"

  if [ ! -f "${LIST}" ]; then
    cp "${PACKAGE_DIR}/kiosk" "${LIST}" 2>/dev/null || echo "http://localhost:3000" >"${LIST}"
  fi

  _select_one

  KIOSK="${SELECTED}"

  if [ -z "${KIOSK}" ]; then
    DEFAULT=""
    if [ -f "${TARGET}" ]; then
      DEFAULT=$(cat "${TARGET}" | xargs)
    fi

    _read "Kiosk URL [${DEFAULT}]: "

    if [ -z "${ANSWER}" ]; then
      KIOSK="${DEFAULT}"
    else
      KIOSK="${ANSWER}"
      echo "${KIOSK}" >>"${LIST}"
    fi

    if [ -z "${KIOSK}" ]; then
      _error "No URL provided"
    fi
  fi

  echo "${KIOSK}" >"${TARGET}"

  _bar
  _echo "Kiosk URL configured: ${KIOSK}" 2
  _bar

  # Setup autostart
  autostart

  _bar
  _echo "Kiosk mode configured. Reboot to apply changes." 2
  _read "Reboot now? [y/N]: "

  if [ "${ANSWER}" == "y" ] || [ "${ANSWER}" == "Y" ]; then
    reboot_system
  fi
}

screensaver() {
  _bar
  _echo "Screensaver Configuration (Wayfire)" 4
  _bar

  # Wayfire configuration (Bookworm default)
  WAYFIRE_CONFIG="${HOME}/.config/wayfire.ini"

  if [ ! -f "${WAYFIRE_CONFIG}" ]; then
    _echo "Wayfire config not found. Creating..." 3
    mkdir -p "${HOME}/.config"
    cat >"${WAYFIRE_CONFIG}" <<EOF
[idle]
screensaver_timeout = -1
dpms_timeout = -1
EOF
    _bar
    _echo "Wayfire screensaver disabled" 2
    cat "${WAYFIRE_CONFIG}"
    _bar
    return
  fi

  backup "${WAYFIRE_CONFIG}"

  # Check if idle section exists
  if ! grep -q "^\[idle\]" "${WAYFIRE_CONFIG}"; then
    cat >>"${WAYFIRE_CONFIG}" <<EOF

[idle]
screensaver_timeout = -1
dpms_timeout = -1
EOF
    _bar
    _echo "Wayfire screensaver disabled" 2
    grep -A 2 "\[idle\]" "${WAYFIRE_CONFIG}"
    _bar
  else
    # Update existing idle section
    sed -i '/^\[idle\]/,/^\[/ s/screensaver_timeout.*/screensaver_timeout = -1/' "${WAYFIRE_CONFIG}"
    sed -i '/^\[idle\]/,/^\[/ s/dpms_timeout.*/dpms_timeout = -1/' "${WAYFIRE_CONFIG}"
    _bar
    _echo "Wayfire screensaver settings updated" 2
    grep -A 2 "\[idle\]" "${WAYFIRE_CONFIG}"
    _bar
  fi

  _bar
  _echo "Screensaver configuration completed" 2
  _echo "Note: Reboot may be required for full effect" 6
  _bar
}

backup() {
  TARGET="${1}"
  BACKUP="${TARGET}.old"

  if [ -f "${TARGET}" ] && [ ! -f "${BACKUP}" ]; then
    cp "${TARGET}" "${BACKUP}"
  fi
}

restore() {
  TARGET="${1}"
  BACKUP="${TARGET}.old"

  if [ -f "${BACKUP}" ]; then
    cp "${BACKUP}" "${TARGET}"
  fi
}

reboot_system() {
  echo "Rebooting in 3 seconds..."
  sleep 3
  sudo reboot
}

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

nginx_add() {
  DOMAIN="${1:-}"
  PORT="${2:-}"

  if [ -z "${DOMAIN}" ] || [ -z "${PORT}" ]; then
    _error "Usage: ${0} nginx add <domain> <port>"
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
    sleep 2

    # Run certbot
    if sudo certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos --redirect --email "admin@${DOMAIN}" 2>/dev/null; then
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

  echo ""
  printf "%-30s %-10s %-10s\n" "DOMAIN" "PORT" "SSL"
  echo "--------------------------------------------------------------------------------"

  for SITE_PATH in ${SITES}; do
    SITE_NAME=$(basename "${SITE_PATH}")

    # Extract port from configuration
    if [ -f "${SITE_PATH}" ]; then
      PORT=$(grep -oP 'proxy_pass.*:(\d+)' "${SITE_PATH}" | grep -oP '\d+' | head -1)
      SSL_STATUS=$(grep -q "listen 443 ssl" "${SITE_PATH}" && echo "✓ Yes" || echo "✗ No")

      if [ -n "${PORT}" ]; then
        printf "%-30s %-10s %-10s\n" "${SITE_NAME}" "${PORT}" "${SSL_STATUS}"
      else
        printf "%-30s %-10s %-10s\n" "${SITE_NAME}" "N/A" "${SSL_STATUS}"
      fi
    fi
  done

  echo ""
  _bar
}

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

nginx_reload() {
  _bar
  _echo "Reloading nginx..." 4
  _bar

  if sudo nginx -t; then
    sudo systemctl reload nginx
    _success "Nginx reloaded successfully!"
  else
    _error "Nginx configuration test failed. Please fix the errors."
  fi
}

nginx_test() {
  _bar
  _echo "Testing nginx configuration..." 4
  _bar

  if sudo nginx -t; then
    _success "Nginx configuration test passed!"
  else
    _error "Nginx configuration test failed!"
  fi
}

nginx_status() {
  _bar
  _echo "Nginx service status:" 4
  _bar
  echo ""

  sudo systemctl status nginx --no-pager

  echo ""
  _bar
}

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

nginx_log() {
  DOMAIN="${1:-}"
  LOG_TYPE="${2:-access}"

  if [ -z "${DOMAIN}" ]; then
    _error "Usage: ${0} nginx log <domain> [access|error]"
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
  echo ""

  if [ -f "${LOG_FILE}" ]; then
    sudo tail -50 "${LOG_FILE}"
  else
    _echo "Log file not found: ${LOG_FILE}" 1
  fi

  echo ""
  _bar
}

nginx_ssl_renew() {
  _bar
  _echo "Renewing SSL certificates..." 4
  _bar

  sudo certbot renew

  _bar
  _success "SSL certificate renewal complete!"
}

nginx() {
  SUBCMD="${1:-}"

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
interfaces)
  enable_interfaces
  ;;
node | nodejs)
  node "${PARAM1}"
  ;;
docker)
  docker
  ;;
nginx)
  nginx "${PARAM1}" "${PARAM2}" "${3:-}"
  ;;
aliases)
  aliases
  ;;
wifi)
  wifi "${PARAM1}" "${PARAM2}"
  ;;
sound)
  sound
  ;;
kiosk)
  kiosk "${PARAM1}"
  ;;
screensaver)
  screensaver
  ;;
*)
  usage
  ;;
esac
