#!/bin/bash

if [ -f /home/pi/.config/rpi-run ]; then
    $(cat /home/pi/.config/rpi-run)
fi

KIOSK=$(cat /home/pi/.config/rpi-kiosk | xargs)

if [ "${KIOSK}" != "" ]; then
    unclutter &
    matchbox-window-manager &
    chromium-browser --incognito --kiosk ${KIOSK}
fi
