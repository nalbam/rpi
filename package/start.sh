#!/bin/bash

if [ -f ${HOME}/.config/rpi-run ]; then
    RUN=$(cat ${HOME}/.config/rpi-run | xargs)

    if [ "${RUN}" != "" ]; then
        $(${RUN})
    fi
fi

if [ -f ${HOME}/.config/rpi-kiosk ]; then
    KIOSK=$(cat ${HOME}/.config/rpi-kiosk | xargs)

    if [ "${KIOSK}" != "" ]; then
        unclutter &
        matchbox-window-manager &
        chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble ${KIOSK}
    fi
fi
