#!/bin/bash

if [ -f /home/pi/.config/rpi-run ]; then
    RUN=$(cat /home/pi/.config/rpi-run | xargs)

    if [ "${RUN}" != "" ]; then
        $(${RUN})
    fi
fi

if [ -f /home/pi/.config/rpi-kiosk ]; then
    KIOSK=$(cat /home/pi/.config/rpi-kiosk | xargs)

    if [ "${KIOSK}" != "" ]; then
        unclutter &
        matchbox-window-manager &
        chromium-browser --incognito --kiosk ${KIOSK}
    fi
fi
