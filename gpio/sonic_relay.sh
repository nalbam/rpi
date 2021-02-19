#!/bin/bash
#
# chkconfig: - 50 50
# description: init file for sonic_relay daemon
#

VAL=0

NAME="sonic_relay"

SHELL_DIR=$(dirname $0)

EXEC=${SHELL_DIR}/${NAME}

start()
{
    echo $"Starting ${NAME}..."

    /usr/bin/sudo /usr/bin/nohup ${EXEC} &>/dev/null &

    echo "ok"
}

stop()
{
    echo $"Stopping ${NAME}..."

    PID=`/bin/ps -ef | /bin/grep "[s]onic_relay" | /bin/grep "[r]oot" | /usr/bin/awk '{print $2}'`
    if [ "${PID}" != "" ]; then
        /usr/bin/sudo /bin/kill -9 ${PID}
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

# * 5 * * * ~/rpi/gpio/sonic_relay.sh restart > /dev/null 2>&1
