#!/bin/sh -e


### BEGIN INIT INFO
# Provides:          rtorrent
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/Stop rtorrent
# Description:       Start/Stop rtorrent sous forme de daemon.
### END INIT INFO



NAME=rtorrentd.sh
SCRIPTNAME=/etc/init.d/$NAME
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

__go() {
          echo "Starting rtorrent... "
          sudo chmod 775 /var/run/screen
          su -l <username> -c "screen -fn -dmS rtd nice -19 rtorrent"
          echo "Terminated"

}

case $1 in
        start)
                __go
        ;;
        stop)
                if [ "$(ps aux | grep -e '.*rtorrent$' -c)" != 0  ]; then
                {
                        echo "Shutting down rtorrent... "
                        kill `ps aux | grep -e '.*SCREEN.*rtorrent$' | awk -F" " '{print $2}'`
                        echo "Terminated"
                }
                else
                {
                        echo "rtorrent not yet started !"
                        echo "Terminated"
                }
                fi
        ;;
        restart)
                if [ "$(ps aux | grep -e '.*rtorrent$' -c)" != 0  ]; then
                {
                        echo "Shutting down rtorrent... "
                        kill `ps aux | grep -e '.*SCREEN.*rtorrent$' | awk -F" " '{print $2}'`
                        __go
                }
                else
                {
                        echo "rtorrent not yet started !"
                        __go
                }
                fi
        ;;
        *)
                echo "Usage: $SCRIPTNAME {start|stop|restart}" >&2
                exit 2
        ;;
esac
