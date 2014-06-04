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
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++ lua-devel lua'
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
#!/bin/bash
#
# chkconfig: - 85 15
# description: Lightweight inotify based sync daemon
#
# processname:  lsyncd
# config:       /etc/lsyncd.conf
# config:       /etc/sysconfig/lsyncd
# pidfile:      /var/run/lsyncd.pid

# Source function library
. /etc/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "\$NETWORKING" = "no" ] && exit 0

LSYNCD_OPTIONS="-pidfile /var/run/lsyncd.pid /etc/lsyncd.conf"

if [ -e /etc/sysconfig/lsyncd ]; then
  . /etc/sysconfig/lsyncd
fi

RETVAL=0

prog="lsyncd"
thelock=/var/lock/subsys/lsyncd

start() {
        [ -f /etc/lsyncd.conf ] || exit 6
        echo -n $"Starting \$prog: "
        if [ \$UID -ne 0 ]; then
                RETVAL=1
                failure
        else
                daemon /usr/bin/lsyncd \$LSYNCD_OPTIONS
                RETVAL=\$?
                [ \$RETVAL -eq 0 ] && touch \$thelock
        fi;
        echo
        return \$RETVAL
}

stop() {
        echo -n $"Stopping \$prog: "
        if [ \$UID -ne 0 ]; then
                RETVAL=1
                failure
        else
                killproc lsyncd
                RETVAL=\$?
                [ \$RETVAL -eq 0 ] && rm -f \$thelock
        fi;
        echo
        return \$RETVAL
}

reload(){
        echo -n $"Reloading \$prog: "
        killproc lsyncd -HUP
        RETVAL=\$?
        echo
        return \$RETVAL
}

restart(){
        stop
        start
}

condrestart(){
    [ -e \$thelock ] && restart
    return 0
}

case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  reload)
        reload
        ;;
  condrestart)
        condrestart
        ;;
  status)
        status lsyncd
        RETVAL=\$?
        ;;
  *)
        echo $"Usage: \$0 {start|stop|status|restart|condrestart|reload}"
        RETVAL=1
esac

exit \$RETVAL
EOF

test -f ${init_file} && chmod +x ${init_file}

#local config_dir='/etc/lsyncd'
local config_file="/etc/lsyncd.conf"
#test -d ${config_dir} || mkdir -p ${config_dir}
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
