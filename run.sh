#!/bin/bash

SHELL_DIR=$(dirname $0)
PACKAGE_DIR=${SHELL_DIR}/package
TEMP_DIR=/tmp

USER=`whoami`

export LC_ALL=C

################################################################################

usage() {
    echo " Usage: ${0} {cmd}"
    echo_bar
    echo_
    echo "${0} init        [vim, fbi, gpio, font]"
    echo "${0} auto        [init, date, keyboard, aliases, locale]"
    echo "${0} arcade      [init, date, keyboard, aliases]"
    echo "${0} update      [self update]"
    echo "${0} upgrade     [apt-get update, upgrade]"
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
    echo_
    echo_bar
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
    pushd "${SHELL_DIR}"
    git pull
    popd
}

upgrade() {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get clean all
    sudo apt-get autoremove -y
}

init() {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y curl wget unzip vim jq fbi dialog wiringpi fonts-unfonts-core
    sudo apt-get clean all
    sudo apt-get autoremove -y
}

localtime() {
    sudo rm -rf /etc/localtime
    sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

    echo_bar
    date
    echo_bar
}

locale() {
    LOCALE=${1:-en_US.UTF-8}

    sudo locale-gen "${LOCALE}"

    TEMPLATE="${PACKAGE_DIR}/locale.txt"
    TARGET="/etc/default/locale"
    TEMP="${TEMP_DIR}/locale.tmp"

    backup ${TARGET}

    sed "s/REPLACE/$LOCALE/g" ${TEMPLATE} > ${TEMP} && sudo cp -rf ${TEMP} ${TARGET}

    echo_bar
    cat ${TARGET}
    echo_bar
}

keyboard() {
    LAYOUT=${1:-us}

    TEMPLATE="${PACKAGE_DIR}/keyboard.txt"
    TARGET="/etc/default/keyboard"
    TEMP="${TEMP_DIR}/keyboard.tmp"

    backup ${TARGET}

    sed "s/REPLACE/$LAYOUT/g" ${TEMPLATE} > ${TEMP} && sudo cp -rf ${TEMP} ${TARGET}

    echo_bar
    cat ${TARGET}
    echo_bar
}

aliases() {
    TEMPLATE="${PACKAGE_DIR}/aliases.txt"
    TARGET="${HOME}/.bash_aliases"

    backup ${TARGET}

    cp -rf ${TEMPLATE} ${TARGET}

    . ${TARGET}

    echo_bar
    cat ${TARGET}
    echo_bar
}

apache() {
    sudo apt-get install -y apache2 php5

    echo_bar
    apache2 -version
    echo_bar
    php -version
    echo_bar
}

lcd() {
    CMD="$1"

    TARGET="/boot/config.txt"
    BACKUP="/boot/config.txt.old"
    TEMP="${TEMP_DIR}/config.tmp"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    case ${CMD} in
        5)
            TEMPLATE="${PACKAGE_DIR}/config-5.txt"
            ;;
        8)
            TEMPLATE="${PACKAGE_DIR}/config-8.txt"
            ;;
        *)
            TEMPLATE=
    esac

    if [ "${TEMPLATE}" == "" ]; then
        restore ${TARGET}

        echo_bar
        echo "restored."
        echo_bar
    else
        # replace
        cp -rf ${BACKUP} ${TEMP}
        echo "" >> ${TEMP}
        cat ${TEMPLATE} >> ${TEMP}
        sudo cp -rf ${TEMP} ${TARGET}

        echo_bar
        cat ${TEMPLATE}
        echo_bar
    fi
}

wifi() {
    SSID="$1"
    PASS="$2"

    TEMPLATE="${PACKAGE_DIR}/wifi.txt"
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

    echo_bar
    sudo cat ${TARGET}
    echo_bar
}

sound() {
    TEMPLATE="${PACKAGE_DIR}/alsa-base.txt"
    TARGET="/etc/modprobe.d/alsa-base.conf"

    if [ ! -f ${TARGET} ]; then
        return 0
    fi

    backup ${TARGET}

    sudo cp -rf ${TEMPLATE} ${TARGET}

    echo_bar
    cat ${TARGET}
    if [ `aplay -l | grep -c "USB Audio"` -gt 0 ]; then
        echo_bar
        aplay -D plughw:0,0 /usr/share/scratch/Media/Sounds/Vocals/Singer2.wav
    else
        echo_bar
        echo "You need reboot. [sudo reboot]"
    fi
    echo_bar
}

mp3() {
    command -v mpg321 > /dev/null || sudo apt-get install -y mpg321

    echo_bar
    mpg321 -o alsa -a plughw:0,0 /usr/share/scratch/Media/Sounds/Vocals/Sing-me-a-song.mp3
    echo_bar
}

speak() {
    MSG=${1:-hi pi}

    command -v espeak > /dev/null || sudo apt-get install -y espeak

    echo_bar
    espeak "${MSG}"
    echo_bar
}

kiosk() {
    NAME="$1"
    CODE="$2"

    if [ "${NAME}" == "" ]; then
        NAME="nalbam"
    elif [ "${NAME}" == "kill" ]; then
        cat ${PACKAGE_DIR}/kiosk-kill.txt | bash
        return
    fi

    command -v unclutter > /dev/null || sudo apt-get install -y unclutter matchbox

    # kiosk.sh
    TEMPLATE="${PACKAGE_DIR}/kiosk-${NAME}.txt"
    TARGET="${HOME}/kiosk.sh"

    sed "s/CODE/$CODE/g" ${TEMPLATE} > ${TARGET}
    chmod 755 ${TARGET}

    echo_bar
    cat ${TARGET}
    echo_bar

    # auto start
    TEMPLATE="${PACKAGE_DIR}/autostart.txt"
    TARGET="${HOME}/.config/lxsession/LXDE-pi/autostart"
    TEMP="${TEMP_DIR}/autostart.tmp"

    if [ `cat ${TARGET} | grep -c "kiosk.sh"` -eq 0 ]; then
        cp -rf ${TARGET} ${TEMP}
        echo "" >> ${TEMP}
        sed "s/USER/$USER/g" ${TEMPLATE} >> ${TEMP}
        sudo cp ${TEMP} ${TARGET}
    fi

    echo_bar
    cat ${TARGET}
    echo_bar

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

    echo_bar
    cat ${TARGET} | grep xserver-command
    echo_bar

    # xinitrc
    TEMPLATE="${PACKAGE_DIR}/xinitrc.txt"
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

    echo_bar
    cat ${TARGET} | grep xset
    echo_bar
}

roms() {
    SERVER="$1"
    if [ "${SERVER}" == "" ]; then
        SERVER="s1.nalbam.com"
    fi

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
    TARGET="$1"
    BACKUP="${TARGET}.old"

    if [ -f ${TARGET} -a ! -f ${BACKUP} ]; then
        sudo cp ${TARGET} ${BACKUP}
    fi
}

restore() {
    TARGET="$1"
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

echo_bar() {
    echo "================================================================================"
}

echo_() {
    echo ""
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
    web|apache)
        apache
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
