#!/bin/bash
#
# chkconfig: - 50 50
# description: init file for voice_player daemon
#

VAL=0

NAME="voice_player"

SHELL_DIR=$(dirname $0)

EXEC=/home/pi/AIY-voice-kit-python/src/examples/voice/voice_player.py

start()
{
    echo $"Starting ${NAME}..."

    /usr/bin/nohup ${EXEC} &>/dev/null &

    echo "ok"
}

stop()
{
    echo $"Stopping ${NAME}..."

    PID=`/bin/ps -ef | /bin/grep "[v]oice_player" | /bin/grep "[r]oot" | /usr/bin/awk '{print $2}'`
    if [ "${PID}" != "" ]; then
        /bin/kill -9 ${PID}
        echo "killed [${PID}]"
    fi
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