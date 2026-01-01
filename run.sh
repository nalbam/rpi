#!/bin/bash

set -euo pipefail

SHELL_DIR=$(dirname "$0")
PACKAGE_DIR="${SHELL_DIR}/package"
TEMP_DIR=/tmp

USER=$(whoami)

command -v tput >/dev/null || TPUT=false

_bar() {
  _echo "================================================================================"
}

_echo() {
  if [ -z ${TPUT} ] && [ -n "${2:-}" ]; then
    echo -e "$(tput setaf "$2")$1$(tput sgr0)"
  else
    echo -e "$1"
  fi
}

_read() {
  if [ -z ${TPUT} ]; then
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

usage() {
  echo " Usage: ${0} {cmd}"
  _bar
  echo
  echo "${0} init        [기본 패키지 설치]"
  echo "${0} auto        [init, aliases]"
  echo "${0} update      [저장소 업데이트]"
  echo "${0} upgrade     [시스템 패키지 업그레이드]"
  echo "${0} aliases     [쉘 별칭 설정]"
  echo "${0} node        [Node.js 20 설치]"
  echo "${0} docker      [Docker 설치]"
  echo "${0} wifi        [WiFi 설정 (NetworkManager)]"
  echo "${0} sound       [오디오 설정 (PulseAudio/PipeWire)]"
  echo "${0} screensaver [화면보호기 비활성화 (Wayfire)]"
  echo "${0} kiosk       [키오스크 모드 설정]"
  echo
  _bar
}

auto() {
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
  sudo apt install -y lgpio libgpiod-dev python3-lgpio python3-gpiod
  sudo apt clean all
  sudo apt autoremove -y
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
  # Download and verify before executing
  SETUP_SCRIPT="${TEMP_DIR}/nodesource_setup.sh"
  curl -fsSL https://deb.nodesource.com/setup_20.x -o "${SETUP_SCRIPT}"

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
  init
  ;;
node | nodejs)
  node
  ;;
docker)
  docker
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
