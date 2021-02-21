#!/bin/bash

NAME="voice_player"

EXEC=/home/pi/AIY-voice-kit-python/src/examples/voice/voice_player.py
STOP=/home/pi/AIY-voice-kit-python/src/examples/voice/voice_stop.py


_hh() {
    HH=$(TZ=Asia/Seoul date +"%H")
    HH=$(( ${HH} + 0 ))
    echo "HH=${HH}"
}

_pid() {
    PID=$(/bin/ps -ef | /bin/grep "[v]oice_player" | /bin/grep "[p]ython" | /usr/bin/awk '{print $2}')
    echo "PID=${PID}"
}

run() {
    _hh

    if [ ${HH} -gt 8 ] && [ ${HH} -lt 22 ]; then
        start
    else
        stop
    fi
}

start() {
    _pid

    if [ "${PID}" != "" ]; then
      exit 1
    fi

    echo "Starting ${NAME}..."

    /usr/bin/python3 ${EXEC}

    _pid

    echo "Started [${PID}]"
}

stop() {
    _pid

    if [ "${PID}" == "" ]; then
      exit 1
    fi

    echo "Stopping ${NAME} [${PID}]..."

    /bin/kill -9 ${PID}

    _pid

    echo "Stopped [${PID}]"

    /usr/bin/python3 ${STOP}
}

case "$1" in
    run)
        run
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart}"
esac

# * * * * * ~/rpi/aiy/voice/voice_player.sh run > /dev/null 2>&1
