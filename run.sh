#!/bin/bash

SHELL_DIR=$(dirname $0)
PACKAGE_DIR=${SHELL_DIR}/package
TEMP_DIR=/tmp

USER=`whoami`

# export LC_ALL=C

command -v tput > /dev/null || TPUT=false

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
        IDX=$(( ${IDX} + 1 ))
        printf "%3s. %s\n" "${IDX}" "${VAL}";
    done < ${LIST}

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
    echo "${0} init        [vim, fbi, gpio, font]"
    echo "${0} auto        [init, date, keyboard, aliases, locale]"
    echo "${0} arcade      [init, date, keyboard, aliases]"
    echo "${0} update      [self update]"
    echo "${0} upgrade     [apt update, upgrade]"
    echo "${0} apache      [apache2, php5]"
    echo "${0} date        [Asia/Seoul]"
    echo "${0} locale      [en_US.UTF-8]"
    echo "${0} keyboard    [keyboard layout]"
    echo "${0} aliases     [ll=ls -l, l=ls -al]"
    echo "${0} sound       [usb-sound]"
    echo "${0} mp3         [mpg321]"
    echo "${0} espeak      [espeak hi]"
    echo "${0} screensaver [not into screensaver]"
    echo "${0} kiosk       [kiosk NAME CODE]"
    echo "${0} wifi        [wifi SSID PASSWD]"
    echo
    _bar
}

auto() {
    init
    locale
    localtime
    keyboard
    aliases
    reboot
}

arcade() {
    init
    localtime
    keyboard
    aliases
    reboot
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
    sudo apt install -y curl wget unzip vim jq fbi dialog wiringpi fonts-unfonts-core
    sudo apt clean all
    sudo apt autoremove -y
}

localtime() {
    sudo rm -rf /etc/localtime
    sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

    _bar
    date
    _bar
}

locale() {
    LOCALE=${1:-en_US.UTF-8}

    sudo locale-gen "${LOCALE}"

    TEMPLATE="${PACKAGE_DIR}/locale.sh"
    TARGET="/etc/default/locale"
    TEMP="${TEMP_DIR}/locale.tmp"

    backup ${TARGET}

    sed "s/REPLACE/$LOCALE/g" ${TEMPLATE} > ${TEMP} && sudo cp -rf ${TEMP} ${TARGET}

    _bar
    cat ${TARGET}
    _bar
}

keyboard() {
    LAYOUT=${1:-us}

    TEMPLATE="${PACKAGE_DIR}/keyboard.sh"
    TARGET="/etc/default/keyboard"
    TEMP="${TEMP_DIR}/keyboard.tmp"

    backup ${TARGET}

    sed "s/REPLACE/$LAYOUT/g" ${TEMPLATE} > ${TEMP} && sudo cp -rf ${TEMP} ${TARGET}

    _bar
    cat ${TARGET}
    _bar
}

aliases() {
    TEMPLATE="${PACKAGE_DIR}/aliases.sh"
    TARGET="${HOME}/.bash_aliases"

    backup ${TARGET}

    cp -rf ${TEMPLATE} ${TARGET}

    . ${TARGET}

    _bar
    cat ${TARGET}
    _bar
}

apache() {
    sudo apt install -y apache2 php5

    _bar
    apache2 -version
    _bar
    php -version
    _bar
}

node() {
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
    sudo apt install -y nodejs npm

    _bar
    node -v
    npm -v
    _bar
}

docker() {
    curl -sSL get.docker.com | sh
    sudo usermod pi -aG docker

    _bar
    docker -v
    _bar
}

lcd() {
    SIZE="$1"

    TARGET="/boot/config.txt"
    BACKUP="/boot/config.txt.old"
    TEMP="${TEMP_DIR}/config.tmp"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    case ${SIZE} in
        5)
            TEMPLATE="${PACKAGE_DIR}/config-5.sh"
            ;;
        8)
            TEMPLATE="${PACKAGE_DIR}/config-8.sh"
            ;;
        *)
            TEMPLATE=
    esac

    if [ "${TEMPLATE}" == "" ]; then
        restore ${TARGET}

        _bar
        echo "restored."
        _bar
    else
        # replace
        cp -rf ${BACKUP} ${TEMP}
        echo "" >> ${TEMP}
        cat ${TEMPLATE} >> ${TEMP}
        sudo cp -rf ${TEMP} ${TARGET}

        _bar
        cat ${TEMPLATE}
        _bar
    fi
}

wifi() {
    SSID="$1"
    PASS="$2"

    TEMPLATE="${PACKAGE_DIR}/wifi.conf"
    TARGET="/etc/wpa_supplicant/wpa_supplicant.conf"
    TEMP="${TEMP_DIR}/wifi.tmp"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    if [ "${PASS}" != "" ]; then
        sudo cp -rf ${TEMPLATE} ${TARGET}

        sudo sed "s/SSID/$SSID/g" ${TARGET} > ${TEMP} && sudo cp -rf ${TEMP} ${TARGET}
        sudo sed "s/PASS/$PASS/g" ${TARGET} > ${TEMP} && sudo cp -rf ${TEMP} ${TARGET}
    fi

    _bar
    sudo cat ${TARGET}
    _bar
}

sound() {
    TEMPLATE="${PACKAGE_DIR}/alsa-base.conf"
    TARGET="/etc/modprobe.d/alsa-base.conf"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    sudo cp -rf ${TEMPLATE} ${TARGET}

    _bar
    cat ${TARGET}
    if [ `aplay -l | grep -c "USB Audio"` -gt 0 ]; then
        _bar
        aplay -D plughw:0,0 /usr/share/scratch/Media/Sounds/Vocals/Singer2.wav
    else
        _bar
        echo "You need reboot. [sudo reboot]"
    fi
    _bar
}

mp3() {
    command -v mpg321 > /dev/null || sudo apt install -y mpg321

    _bar
    mpg321 -o alsa -a plughw:0,0 /usr/share/scratch/Media/Sounds/Vocals/Sing-me-a-song.mp3
    _bar
}

speak() {
    MSG=${1:-hi pi}

    command -v espeak > /dev/null || sudo apt install -y espeak

    _bar
    espeak "${MSG}"
    _bar
}

autostart() {
    # url
    TARGET="${HOME}/.config/rpi-kiosk"

    LIST="${HOME}/.config/rpi-kiosk-list"

    if [ ! -f ${LIST} ]; then
        cp ${PACKAGE_DIR}/kiosk ${LIST}
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
            echo "${KIOSK}" >> ${LIST}
        fi

        if [ "${KIOSK}" == "" ]; then
            _error
        fi
    fi

    if [ -f ${TEMPLATE} ]; then
        sed "s/CODE/$CODE/g" ${TEMPLATE} > ${TARGET}
    else
        echo "${KIOSK}" > ${TARGET}
    fi

    # start.sh
    TEMPLATE="${PACKAGE_DIR}/start.sh"
    TARGET="${HOME}/start.sh"

    cp -rf ${TEMPLATE} ${TARGET}
    chmod 755 ${TARGET}

    _bar
    cat ${TARGET}
    _bar

    # auto start
    TEMPLATE="${PACKAGE_DIR}/autostart.sh"
    TARGET="${HOME}/.config/lxsession/LXDE-pi/autostart"

    backup ${TARGET}
    cp -rf ${TEMPLATE} ${TARGET}

    _bar
    cat ${TARGET}
    _bar

}

scan() {
    CMD="${1}"

    if [ "${CMD}" == "stop" ]; then
        rm -rf ${HOME}/.config/rpi-run

        killall chromium-browser
        return
    fi

    command -v arp-scan > /dev/null || sudo apt install -y arp-scan

    command -v unclutter > /dev/null || sudo apt install -y unclutter matchbox

    if [ ! -d ${HOME}/wifi-spi ]; then
        git clone https://github.com/nalbam/wifi-spi ${HOME}/wifi-spi
    else
        pushd ${HOME}/wifi-spi
        git pull
        popd
    fi

    pushd ${HOME}/wifi-spi/src
    npm install
    popd

    echo "${HOME}/wifi-spi/run.sh" > ${HOME}/.config/rpi-run

    autostart

    reboot
}

kiosk() {
    CMD="${1}"

    if [ "${CMD}" == "stop" ]; then
        killall chromium-browser
        return
    fi

    command -v unclutter > /dev/null || sudo apt install -y unclutter matchbox

    autostart

    reboot
}

screensaver() {
    # lightdm
    TARGET="/etc/lightdm/lightdm.conf"
    TEMP="${TEMP_DIR}/lightdm.tmp"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    # xserver-command=X -s 0 -dpms
    sed "s/\#xserver\-command\=X/xserver-command\=X \-s 0 \-dpms/g" ${TARGET} > ${TEMP}
    sudo cp -rf ${TEMP} ${TARGET}

    _bar
    cat ${TARGET} | grep xserver-command
    _bar

    # xinitrc
    TEMPLATE="${PACKAGE_DIR}/xinitrc.sh"
    TARGET="/etc/X11/xinit/xinitrc"
    TEMP="${TEMP_DIR}/xinitrc.tmp"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    if [ `cat ${TARGET} | grep -c "screensaver"` -eq 0 ]; then
        cp -rf ${TARGET} ${TEMP}
        echo "" >> ${TEMP}
        cat ${TEMPLATE} >> ${TEMP}
        sudo cp ${TEMP} ${TARGET}
    fi

    _bar
    cat ${TARGET} | grep xset
    _bar
}

roms() {
    SERVER="${1:-roms.nalbam.com}"

    rsync -av --bwlimit=2048 ${SERVER}:/home/pi/RetroPie/roms/ /home/pi/RetroPie/roms/
}

replace() {
    sudo sed "s/$1/$2/g" $3 > "$3.tmp"
    sudo cp -rf "$3.tmp" $3

    if [ "${USER}" != "" ]; then
        sudo chown ${USER}.${USER} $3
    fi
}

backup() {
    TARGET="${1}"
    BACKUP="${TARGET}.old"

    if [ -f ${TARGET} -a ! -f ${BACKUP} ]; then
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
    arcade|picade|game)
        arcade
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
    apache)
        apache
        ;;
    node|nodejs)
        node
        ;;
    docker)
        docker
        ;;
    lcd)
        lcd "${PARAM1}"
        ;;
    date|localtime)
        localtime
        ;;
    locale)
        locale "${PARAM1}"
        ;;
    keyboard)
        keyboard "${PARAM1}"
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
    mp3|mpg321)
        mp3
        ;;
    speak|espeak)
        speak "${PARAM1}"
        ;;
    scan)
        scan "${PARAM1}" "${PARAM2}"
        ;;
    kiosk)
        kiosk "${PARAM1}" "${PARAM2}"
        ;;
    roms)
        roms "${PARAM1}"
        ;;
    screensaver)
        screensaver
        ;;
    *)
        usage
esac
