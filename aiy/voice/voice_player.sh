#!/bin/bash

NAME="voice_player"

EXEC=/home/pi/AIY-voice-kit-python/src/examples/voice/voice_player.py
STOP=/home/pi/AIY-voice-kit-python/src/examples/voice/voice_stop.py


_hh() {
    HH=$(TZ=Asia/Seoul date +"%H")
}

_pid() {
    PID=$(/bin/ps -ef | /bin/grep "[v]oice_player" | /bin/grep "[p]ython" | /usr/bin/awk '{print $2}')
}

start()
{
    _hh
    _pid

    if [ "${HH}" -lt "09" ] && [ "${HH}" -gt "20" ]; then
      exit 0
    fi

    if [ "${PID}" != "" ]; then
      exit 1
    fi

    echo "Starting ${NAME}..."

    /usr/bin/nohup /usr/bin/python3 ${EXEC} &>/dev/null &

    _pid

    echo "Started [${PID}]"
}

stop()
{
    _hh
    _pid

    if [ "${HH}" -gt "08" ] && [ "${HH}" -lt "21" ]; then
      exit 0
    fi

    if [ "${PID}" == "" ]; then
      exit 1
    fi

    echo "Stopping ${NAME} [${PID}]..."

    /bin/kill -9 ${PID}

    _pid

    echo "Stopped [${PID}]"

    /usr/bin/nohup /usr/bin/python3 ${STOP} &>/dev/null &
}

case "$1" in
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

# * 5 * * * ~/rpi/aiy/voice/voice_player.sh restart > /dev/null 2>&1
