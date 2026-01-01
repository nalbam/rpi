#!/bin/bash

SHELL_DIR=$(dirname $0)
PACKAGE_DIR=${SHELL_DIR}/package
TEMP_DIR=/tmp

USER=$(whoami)

command -v tput >/dev/null || TPUT=false

_bar() {
  _echo "================================================================================"
}

_echo() {
  if [ -z ${TPUT} ] && [ ! -z $2 ]; then
    echo -e "$(tput setaf $2)$1$(tput sgr0)"
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
    IDX=$((${IDX} + 1))
    printf "%3s. %s\n" "${IDX}" "${VAL}"
  done <${LIST}

  CNT=$(cat ${LIST} | wc -l | xargs)

  echo
  _read "Please select one. (1-${CNT}) : "

  SELECTED=
  if [ -z ${ANSWER} ]; then
    return
  fi
  TEST='^[0-9]+$'
  if ! [[ ${ANSWER} =~ ${TEST} ]]; then
    return
  fi
  SELECTED=$(sed -n ${ANSWER}p ${LIST})
}

_result() {
  _echo "# $@" 4
}

_command() {
  _echo "$ $@" 3
}

_success() {
  _echo "+ $@" 2
  exit 0
}

_error() {
  _echo "- $@" 1
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
  echo "${0} wifi        [WiFi 설정]"
  echo "${0} sound       [USB 오디오 설정]"
  echo "${0} screensaver [화면보호기 비활성화]"
  echo "${0} kiosk       [키오스크 모드 설정]"
  echo
  _bar
}

auto() {
  init
  aliases
}

update() {
  pushd ${SHELL_DIR}
  git pull
  popd
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
  sudo apt clean all
  sudo apt autoremove -y
}

aliases() {
  TEMPLATE="${PACKAGE_DIR}/aliases.sh"
  TARGET="${HOME}/.bash_aliases"

  backup ${TARGET}

  cp -rf ${TEMPLATE} ${TARGET}

  _bar
  cat ${TARGET}
  _bar
}

node() {
  sudo curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  sudo apt install -y nodejs

  _bar
  node -v
  npm -v
  _bar
}

docker() {
  curl -sSL get.docker.com | sh
  sudo usermod ${USER} -aG docker

  _bar
  docker -v
  _bar
}

wifi() {
  SSID="$1"
  PASS="$2"

  if [ -z "${SSID}" ] || [ -z "${PASS}" ]; then
    _error "Usage: $0 wifi SSID PASSWORD"
  fi

  # NetworkManager가 실행 중인지 확인
  if systemctl is-active --quiet NetworkManager; then
    _echo "Using NetworkManager..." 3

    # 기존 연결 삭제 (있다면)
    nmcli connection delete "${SSID}" 2>/dev/null || true

    # 새 WiFi 연결 추가
    nmcli device wifi connect "${SSID}" password "${PASS}"

    if [ $? -eq 0 ]; then
      _bar
      _echo "WiFi connected successfully via NetworkManager" 2
      nmcli connection show "${SSID}"
      _bar
    else
      _error "Failed to connect to WiFi via NetworkManager"
    fi
  else
    # NetworkManager가 없으면 wpa_supplicant 방식 사용 (레거시)
    _echo "Using wpa_supplicant (legacy)..." 3

    TEMPLATE="${PACKAGE_DIR}/wifi.conf"
    TARGET="/etc/wpa_supplicant/wpa_supplicant.conf"

    if [ ! -f ${TARGET} ]; then
      _error "Not found [${TARGET}]"
    fi

    backup ${TARGET}

    sudo cp -rf ${TEMPLATE} ${TARGET}
    sudo sed -i "s/SSID/$SSID/g" ${TARGET}
    sudo sed -i "s/PASS/$PASS/g" ${TARGET}

    _bar
    sudo cat ${TARGET}
    _bar

    _echo "WiFi configured. Restart networking or reboot." 3
  fi
}

sound() {
  _bar
  _echo "Audio Configuration" 4
  _bar

  # 오디오 장치 목록 표시
  _echo "Available audio devices:" 3
  aplay -l

  _bar

  # PulseAudio/PipeWire 확인
  if command -v pactl >/dev/null; then
    _echo "Using PulseAudio/PipeWire (recommended)" 2
    _bar
    pactl list short sinks

    _bar
    _echo "To change default audio output, use:" 3
    _echo "  raspi-config -> System Options -> Audio" 6
    _echo "Or use GUI: pavucontrol (install: sudo apt install pavucontrol)" 6
    _bar
  else
    # 레거시 ALSA 설정
    _echo "Using legacy ALSA configuration..." 3

    TEMPLATE="${PACKAGE_DIR}/alsa-base.conf"
    TARGET="/etc/modprobe.d/alsa-base.conf"

    if [ -f ${TARGET} ]; then
      backup ${TARGET}
      sudo cp -rf ${TEMPLATE} ${TARGET}

      _bar
      cat ${TARGET}
      _bar
      _echo "Configuration applied. Reboot required." 3
    else
      _echo "ALSA config not found. Use raspi-config instead." 6
    fi
  fi

  _bar
  _echo "Test audio with: speaker-test -t wav -c 2" 6
  _bar
}

autostart() {
  # start.sh 복사
  TEMPLATE="${PACKAGE_DIR}/start.sh"
  TARGET="${HOME}/start.sh"

  cp -rf ${TEMPLATE} ${TARGET}
  chmod 755 ${TARGET}

  _bar
  _echo "Start script created: ${TARGET}" 2
  cat ${TARGET}
  _bar

  # Desktop 환경 감지
  if [ ! -z "$XDG_CURRENT_DESKTOP" ]; then
    DESKTOP_ENV="$XDG_CURRENT_DESKTOP"
  elif [ -d "${HOME}/.config/lxsession/LXDE-pi" ]; then
    DESKTOP_ENV="LXDE"
  elif [ -f "${HOME}/.config/wayfire.ini" ]; then
    DESKTOP_ENV="wayfire"
  else
    DESKTOP_ENV="unknown"
  fi

  _echo "Detected desktop environment: ${DESKTOP_ENV}" 3

  # LXDE 자동시작 설정
  if [ -d "${HOME}/.config/lxsession" ] || [ "${DESKTOP_ENV}" == "LXDE" ]; then
    mkdir -p ${HOME}/.config/lxsession/LXDE-pi
    TEMPLATE="${PACKAGE_DIR}/autostart.sh"
    TARGET="${HOME}/.config/lxsession/LXDE-pi/autostart"

    backup ${TARGET}
    cp -rf ${TEMPLATE} ${TARGET}
    sed -i "s|START_SCRIPT_PATH|${HOME}/start.sh|g" ${TARGET}

    _bar
    _echo "LXDE autostart configured: ${TARGET}" 2
    cat ${TARGET}
    _bar
  fi

  # XDG autostart 설정 (Wayfire, GNOME, etc.)
  mkdir -p ${HOME}/.config/autostart
  DESKTOP_FILE="${HOME}/.config/autostart/rpi-startup.desktop"

  cat >${DESKTOP_FILE} <<EOF
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
  cat ${DESKTOP_FILE}
  _bar
}

kiosk() {
  CMD="${1}"

  if [ "${CMD}" == "stop" ]; then
    killall chromium-browser 2>/dev/null || killall chromium 2>/dev/null
    rm -f ${HOME}/.config/rpi-kiosk
    _echo "Kiosk mode stopped" 2
    return
  fi

  # 필요한 패키지 설치
  command -v unclutter >/dev/null || sudo apt install -y unclutter
  command -v matchbox-window-manager >/dev/null || sudo apt install -y matchbox-window-manager

  # URL 설정
  TARGET="${HOME}/.config/rpi-kiosk"
  LIST="${HOME}/.config/rpi-kiosk-list"

  if [ ! -f ${LIST} ]; then
    cp ${PACKAGE_DIR}/kiosk ${LIST} 2>/dev/null || echo "http://localhost:3000" >${LIST}
  fi

  _select_one

  KIOSK="${SELECTED}"

  if [ "${KIOSK}" == "" ]; then
    if [ -f ${TARGET} ]; then
      DEFAULT=$(cat ${TARGET} | xargs)
    fi

    _read "Kiosk URL [${DEFAULT}]: "

    if [ "${ANSWER}" == "" ]; then
      KIOSK="${DEFAULT}"
    else
      KIOSK="${ANSWER}"
      echo "${KIOSK}" >>${LIST}
    fi

    if [ "${KIOSK}" == "" ]; then
      _error "No URL provided"
    fi
  fi

  echo "${KIOSK}" >${TARGET}

  _bar
  _echo "Kiosk URL configured: ${KIOSK}" 2
  _bar

  # 자동시작 설정
  autostart

  _bar
  _echo "Kiosk mode configured. Reboot to apply changes." 2
  _read "Reboot now? [y/N]: "

  if [ "${ANSWER}" == "y" ] || [ "${ANSWER}" == "Y" ]; then
    reboot
  fi
}

screensaver() {
  _bar
  _echo "Screensaver Configuration" 4
  _bar

  # 환경 감지
  if [ "$XDG_SESSION_TYPE" == "wayland" ] || [ -f "${HOME}/.config/wayfire.ini" ]; then
    _echo "Detected Wayland environment" 3

    # Wayfire 설정
    WAYFIRE_CONFIG="${HOME}/.config/wayfire.ini"

    if [ -f ${WAYFIRE_CONFIG} ]; then
      backup ${WAYFIRE_CONFIG}

      # idle 섹션이 없으면 추가
      if ! grep -q "^\[idle\]" ${WAYFIRE_CONFIG}; then
        cat >>${WAYFIRE_CONFIG} <<EOF

[idle]
screensaver_timeout = -1
dpms_timeout = -1
EOF
        _bar
        _echo "Wayfire screensaver disabled" 2
        cat ${WAYFIRE_CONFIG} | grep -A 2 "\[idle\]"
        _bar
      else
        # idle 섹션이 있으면 값만 수정
        sed -i '/^\[idle\]/,/^\[/ s/screensaver_timeout.*/screensaver_timeout = -1/' ${WAYFIRE_CONFIG}
        sed -i '/^\[idle\]/,/^\[/ s/dpms_timeout.*/dpms_timeout = -1/' ${WAYFIRE_CONFIG}
        _bar
        _echo "Wayfire screensaver settings updated" 2
        cat ${WAYFIRE_CONFIG} | grep -A 2 "\[idle\]"
        _bar
      fi
    else
      _echo "Wayfire config not found. Creating..." 3
      mkdir -p ${HOME}/.config
      cat >${WAYFIRE_CONFIG} <<EOF
[idle]
screensaver_timeout = -1
dpms_timeout = -1
EOF
      _bar
      _echo "Wayfire screensaver disabled" 2
      cat ${WAYFIRE_CONFIG}
      _bar
    fi
  else
    # X11 환경
    _echo "Detected X11 environment" 3

    # lightdm 설정
    TARGET="/etc/lightdm/lightdm.conf"

    if [ -f ${TARGET} ]; then
      backup ${TARGET}
      sudo sed -i "s/\#xserver\-command\=X/xserver-command\=X \-s 0 \-dpms/g" ${TARGET}

      _bar
      _echo "LightDM screensaver disabled" 2
      cat ${TARGET} | grep xserver-command
      _bar
    fi

    # xinitrc 설정
    TEMPLATE="${PACKAGE_DIR}/xinitrc.sh"
    TARGET="/etc/X11/xinit/xinitrc"
    TEMP="${TEMP_DIR}/xinitrc.tmp"

    if [ -f ${TARGET} ]; then
      backup ${TARGET}

      if [ $(cat ${TARGET} | grep -c "screensaver") -eq 0 ]; then
        cp -rf ${TARGET} ${TEMP}
        echo "" >>${TEMP}
        cat ${TEMPLATE} >>${TEMP}
        sudo cp ${TEMP} ${TARGET}
      fi

      _bar
      _echo "X11 screensaver disabled" 2
      cat ${TARGET} | grep xset
      _bar
    fi

    # 현재 세션에서 즉시 적용 (X11)
    if command -v xset >/dev/null && [ ! -z "$DISPLAY" ]; then
      xset s off
      xset -dpms
      xset s noblank
      _echo "Applied to current X11 session" 2
    fi
  fi

  _bar
  _echo "Screensaver configuration completed" 2
  _echo "Note: Reboot may be required for full effect" 6
  _bar
}

backup() {
  TARGET="${1}"
  BACKUP="${TARGET}.old"

  if [ -f ${TARGET} ] && [ ! -f ${BACKUP} ]; then
    sudo cp ${TARGET} ${BACKUP}
  fi
}

restore() {
  TARGET="${1}"
  BACKUP="${TARGET}.old"

  if [ -f ${BACKUP} ]; then
    sudo cp ${BACKUP} ${TARGET}
  fi
}

reboot() {
  echo "Now reboot..."
  sleep 3
  sudo reboot
}

################################################################################

CMD=$1
PARAM1=$2
PARAM2=$3

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
