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

        # Use chromium (Bookworm) or chromium-browser (legacy) command
        if command -v chromium >/dev/null 2>&1; then
            chromium --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble "${KIOSK}"
        elif command -v chromium-browser >/dev/null 2>&1; then
            chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble "${KIOSK}"
        else
            echo "Error: chromium or chromium-browser not found" >&2
            exit 1
        fi
    fi
fi
