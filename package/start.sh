#!/bin/bash

set -euo pipefail

# Execute custom run script if configured
if [ -f "${HOME}/.config/rpi-run" ]; then
    RUN=$(cat "${HOME}/.config/rpi-run" | xargs)

    if [ -n "${RUN}" ]; then
        # Safely execute the script
        if [ -x "${RUN}" ]; then
            "${RUN}"
        else
            bash "${RUN}"
        fi
    fi
fi

# Start kiosk mode if configured
if [ -f "${HOME}/.config/rpi-kiosk" ]; then
    KIOSK=$(cat "${HOME}/.config/rpi-kiosk" | xargs)

    if [ -n "${KIOSK}" ]; then
        unclutter &
        matchbox-window-manager &
        chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble "${KIOSK}"
    fi
fi
