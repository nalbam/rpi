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
    echo "${0} auto        [init, aliases]"
    # echo "${0} auto        [init, date, keyboard, aliases, locale]"
    # echo "${0} arcade      [init, date, keyboard, aliases]"
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
    echo "${0} mirror      [MagicMirror]"
    echo "${0} wifi        [wifi SSID PASSWD]"
    echo
    _bar
}

auto() {
    init
    # locale
    # localtime
    # keyboard
    aliases
    # reboot
}

arcade() {
    init
    # localtime
    # keyboard
    aliases
    # reboot
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
    sudo apt install -y curl wget unzip vim jq fbi dialog wiringpi \
                        fonts-unfonts-core p7zip-full python3-pip qt5-default \
                        xscreensaver
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

    TEMPLATE="${PACKAGE_DIR}/locale.sh"
    TARGET="/etc/default/locale"

    sudo locale-gen "${LOCALE}"

    backup ${TARGET}

    sudo cp -rf ${TEMPLATE} ${TARGET}
    sudo sed -i "s/REPLACE/${LOCALE}/g" ${TARGET}

    _bar
    cat ${TARGET}
    _bar
}

keyboard() {
    LAYOUT=${1:-us}

    TEMPLATE="${PACKAGE_DIR}/keyboard.sh"
    TARGET="/etc/default/keyboard"

    backup ${TARGET}

    sudo cp -rf ${TEMPLATE} ${TARGET}
    sudo sed -i "s/REPLACE/${LAYOUT}/g" ${TARGET}

    _bar
    cat ${TARGET}
    _bar
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

    if [ ! -f ${TARGET} ]; then
        _error "Not found [${TARGET}]"
    fi

    backup ${TARGET}

    case ${SIZE} in
        5)
            TEMPLATE="${PACKAGE_DIR}/config-5.conf"
            ;;
        5w)
            TEMPLATE="${PACKAGE_DIR}/config-5w.conf"
            ;;
        8)
            TEMPLATE="${PACKAGE_DIR}/config-8.conf"
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
        BACKUP="/boot/config.txt.old"
        TEMP="${TEMP_DIR}/config.tmp"

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

    if [ ! -f ${TARGET} ]; then
        _error "Not found [${TARGET}]"
    fi

    backup ${TARGET}

    if [ "${PASS}" != "" ]; then
        sudo cp -rf ${TEMPLATE} ${TARGET}

        sudo sed -i "s/SSID/$SSID/g" ${TARGET}
        sudo sed -i "s/PASS/$PASS/g" ${TARGET}
    fi

    _bar
    sudo cat ${TARGET}
    _bar
}

qr() {
    command -v zbarimg > /dev/null || sudo apt install -y zbar-tools

    _command "raspistill -w 960 -h 720 -t 500 -n -th none -x none -o image.jpg"
    raspistill -w 960 -h 720 -t 500 -n -th none -x none -o image.jpg

    _command "zbarimg image.jpg"
    zbarimg image.jpg
}

still() {
    command -v fbi > /dev/null || sudo apt install -y fbi

    _command "raspistill -w 960 -h 720 -t 1000 -th none -x none -o image.jpg"
    raspistill -w 960 -h 720 -t 1000 -th none -x none -o image.jpg

    _command "fbi -a image.jpg"
    fbi -a image.jpg
}

motion() {
    command -v motion > /dev/null || sudo apt install -y motion

    sudo cp ${PACKAGE_DIR}/motion.conf /etc/motion/motion.conf

    PICAM=$(cat /etc/modules | grep 'bcm2835-v4l2' | wc -l | xargs)
    if [ "x${PICAM}" == "x0" ]; then
        TEMP="${TEMP_DIR}/modules.tmp"
        TARGET=/etc/modules

        cat ${TARGET} > ${TEMP}
        echo "bcm2835-v4l2" >> ${TEMP}

        sudo cp ${TEMP} ${TARGET}
    fi
}

sound() {
    TEMPLATE="${PACKAGE_DIR}/alsa-base.conf"
    TARGET="/etc/modprobe.d/alsa-base.conf"

    if [ ! -f ${TARGET} ]; then
        _error "Not found [${TARGET}]"
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
    _command "espeak '${MSG}'"
    espeak "${MSG}"
    _bar
}

autostart() {
    # start.sh
    TEMPLATE="${PACKAGE_DIR}/start.sh"
    TARGET="${HOME}/start.sh"

    cp -rf ${TEMPLATE} ${TARGET}
    chmod 755 ${TARGET}

    _bar
    cat ${TARGET}
    _bar

    # auto start
    # /etc/xdg/lxsession/LXDE-pi/autostart
    mkdir -p ${HOME}/.config/lxsession/LXDE-pi
    TEMPLATE="${PACKAGE_DIR}/autostart.sh"
    TARGET="${HOME}/.config/lxsession/LXDE-pi/autostart"

    backup ${TARGET}
    cp -rf ${TEMPLATE} ${TARGET}

    _bar
    cat ${TARGET}
    _bar
}

mirror() {
    CMD="${1}"

    if [ "${CMD}" == "stop" ]; then
        rm -rf ${HOME}/.config/rpi-run

        return
    fi

    # pushd ${HOME}/MagicMirror
    # npm install
    # popd

    echo "${PACKAGE_DIR}/mirror.sh" > ${HOME}/.config/rpi-run

    autostart

    reboot
}

rek() {
    CMD="${1}"

    if [ "${CMD}" == "stop" ]; then
        rm -rf ${HOME}/.config/rpi-run

        killall chromium-browser
        return
    fi

    command -v unclutter > /dev/null || sudo apt install -y unclutter matchbox

    if [ ! -d ${HOME}/rpi-rek ]; then
        git clone https://github.com/nalbam/rpi-rek ${HOME}/rpi-rek
    else
        pushd ${HOME}/rpi-rek
        git pull
        popd
    fi

    pushd ${HOME}/rpi-rek/src
    npm install
    popd

    echo "${HOME}/rpi-rek/run.sh" > ${HOME}/.config/rpi-run

    autostart

    reboot
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

    if [ ! -d ${HOME}/rpi-scan ]; then
        git clone https://github.com/nalbam/rpi-scan ${HOME}/rpi-scan
    else
        pushd ${HOME}/rpi-scan
        git pull
        popd
    fi

    pushd ${HOME}/rpi-scan/src
    npm install
    popd

    echo "${HOME}/rpi-scan/run.sh" > ${HOME}/.config/rpi-run

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

    echo "${KIOSK}" > ${TARGET}

    if [ "${CODE}" != "" ]; then
        sed -i "s/CODE/$CODE/g" ${TARGET}
    fi

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
    sudo sed -i "s/\#xserver\-command\=X/xserver-command\=X \-s 0 \-dpms/g" ${TARGET}

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
    qr)
        qr
        ;;
    still)
        still
        ;;
    motion)
        motion
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
    rek)
        rek "${PARAM1}" "${PARAM2}"
        ;;
    scan)
        scan "${PARAM1}" "${PARAM2}"
        ;;
    kiosk)
        kiosk "${PARAM1}" "${PARAM2}"
        ;;
    mirror)
        mirror "${PARAM1}" "${PARAM2}"
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
