#!/bin/sh
#
### BEGIN INIT INFO
# Provides:          sesame
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog $network
# Should-Start:
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start or stop sesame
# Description:       sesame is a QMF system information provider which uses
#                    the AMQP protcol.
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

DAEMON=/usr/sbin/sesame
NAME=sesame
DESC="sesame QMF provider"
LOGDIR=/var/log/qpid
STARTTIME=2
PIDFILE=/var/run/sesame/$NAME.pid

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

DIETIME=10
RUN="no"
DAEMONUSER=sesame
SESAME_OPTIONS=""

# Include defaults if available
if [ -f /etc/default/sesame ] ; then
        . /etc/default/sesame
fi

if [ "x$RUN" != "xyes" ] ; then
	echo "$NAME disabled; edit /etc/default/$NAME"
	exit 0
fi

# Check that the user exists (if we set a user)
# Does the user exist?
if [ -n "$DAEMONUSER" ] ; then
    if getent passwd | grep -q "^$DAEMONUSER:"; then
        # Obtain the uid and gid
        DAEMONUID=`getent passwd |grep "^$DAEMONUSER:" | awk -F : '{print $3}'`
        DAEMONGID=`getent passwd |grep "^$DAEMONUSER:" | awk -F : '{print $4}'`
    else
        log_failure_msg "The user $DAEMONUSER, required to run $NAME does not exist."
        exit 1
    fi
fi

set -e

case "$1" in
  start)
        echo -n "Starting $DESC: "
        start-stop-daemon --start --quiet --pidfile /var/run/$NAME.pid \
                --exec $DAEMON --chuid $DAEMONUSER -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon --stop --oknodo --quiet --pidfile /var/run/$NAME.pid \
                --exec $DAEMON
        echo "$NAME."
        ;;
  force-reload)
        # check whether $DAEMON is running. If so, restart
        start-stop-daemon --stop --test --quiet --pidfile \
                /var/run/$NAME.pid --exec $DAEMON \
        && $0 restart \
        || exit 0
        ;;
  restart)
        echo -n "Restarting $DESC: "
        start-stop-daemon --stop --oknodo --quiet --pidfile \
                /var/run/$NAME.pid --exec $DAEMON
        sleep 1
        start-stop-daemon --start --quiet --chuid $DAEMONUSER --pidfile \
                /var/run/$NAME.pid --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  status)
        if [ -s /var/run/$NAME.pid ]; then
            RUNNING=$(cat /var/run/$NAME.pid)
            if [ -d /proc/$RUNNING ]; then
                if [ $(readlink /proc/$RUNNING/exe) = $DAEMON ]; then
                    echo "$NAME is running."
                    exit 0
                fi
            fi

            # No such PID, or executables don't match
            echo "$NAME is not running, but pidfile existed."
            rm /var/run/$NAME.pid
            exit 1
        else
            rm -f /var/run/$NAME.pid
            echo "$NAME not running."
            exit 1
        fi
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
