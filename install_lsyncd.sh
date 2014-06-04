#!/bin/bash

#SET ENV
YUM_SERVER='yum.suixingpay.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
#YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++'
#APT_PACKAGE='build-essential'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

config_lsyncd () {
local init_file='/etc/init.d/lsyncd'
cat << EOF > ${init_file}
#! /bin/sh
### BEGIN INIT INFO
# Provides:          lsyncd
# Required-Start:    \$remote_fs
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: lsyncd daemon init script
# Description:       This script launches the lsyncd daemon.
### END INIT INFO

# Author: Ignace Mouzannar <ignace@enovance.com>

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="synchronization daemon"
NAME=lsyncd
DAEMON=/usr/bin/\$NAME
CONFIG=/etc/lsyncd/lsyncd.conf.lua
PIDFILE=/var/run/\$NAME.pid
DAEMON_ARGS="-pidfile \${PIDFILE} \${CONFIG}"
SCRIPTNAME=/etc/init.d/\$NAME

# Exit if the package is not installed
[ -x "\$DAEMON" ] || exit 0

# Exit if config file does not exist
[ -r "\$CONFIG" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/\$NAME ] && . /etc/default/\$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
        start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON \
        --test > /dev/null \
                || return 1
        start-stop-daemon --start --quiet --make-pidfile --pidfile \$PIDFILE \
        --exec \$DAEMON -- \
                \$DAEMON_ARGS \
                || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
        start-stop-daemon --stop --quiet --pidfile \$PIDFILE --name \$NAME
        RETVAL="\$?"
        [ "\$RETVAL" = 2 ] && return 2
        start-stop-daemon --stop --quiet --oknodo --exec \$DAEMON
        [ "\$?" = 2 ] && return 2
        # Many daemons don't delete their pidfiles when they exit.
        rm -f \$PIDFILE
        return "\$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
        start-stop-daemon --stop --signal 1 --quiet --pidfile \$PIDFILE --name \$NAME
        return 0
}

case "\$1" in
  start)
        [ "\$VERBOSE" != no ] && log_daemon_msg "Starting \$DESC" "\$NAME"
        do_start
        case "\$?" in
                0|1) [ "\$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "\$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "\$VERBOSE" != no ] && log_daemon_msg "Stopping \$DESC" "\$NAME"
        do_stop
        case "\$?" in
                0|1) [ "\$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "\$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  status)
        status_of_proc \$DAEMON \$NAME && exit 0 || exit \$?
        ;;
  restart|force-reload)
        log_daemon_msg "Restarting \$DESC" "\$NAME"
        do_stop
        case "\$?" in
          0|1)
                do_start
                case "\$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
  *)
        echo "Usage: \$SCRIPTNAME {start|stop|restart|force-reload}" >&2
        exit 3
        ;;
esac

:
EOF

test -f ${init_file} && chmod +x ${init_file}

local config_dir='/etc/lsyncd'
local config_file="${config_dir}/lsyncd.conf.lua"
test -d ${config_dir} || mkdir -p ${config_dir}
test -f ${config_file} ||\
echo 'settings = {
        logfile = "/var/log/lsyncd.log",
        statusFile = "/tmp/lsyncd.stat",
        statusInterval = 1,
}

sync{
        default.rsync,
        source="/opt/git/shell/",
        target="192.168.0.20::shell"
}

sync{
        default.rsync,
        source="/opt/git/shell/",
        target="192.168.0.21::shell"
}' > ${config_file}

}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#Install lsyncd-2.1.5
PACKAGE='lsyncd-2.1.5.tar.gz'
create_tmp_dir
download_and_check
run_cmds './configure --prefix=/usr' 'make' 'make install'

#Setting
config_lsyncd

#set auto run
MY_PROJECT='lsyncd'
set_auto_run "${MY_PROJECT}"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
