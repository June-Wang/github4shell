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
YUM_PACKAGE='gcc gcc-c++ openssl openssl-devel glib2-devel pcre-devel bzip2-devel gzip-devel'
APT_PACKAGE='build-essential'

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

##### FOR NGINX #####
set_auto_run () {
        echo '#!/bin/bash
#
# nginx - this script starts and stops the nginx daemin
#
# chkconfig:   - 85 15 
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/nginx/conf/nginx.conf
# pidfile:     /usr/local/nginx/logs/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/usr/sbin/nginx"
prog=$(basename $nginx)

NGINX_CONF_FILE="/etc/nginx/nginx.conf"

lockfile=/var/lock/subsys/nginx

start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    if [ $retval -eq 0 ]; then
        test -e $lockfile && rm -f $lockfile
    fi
    return $retval
}

restart() {
    configtest || return $?
    stop
    start
}

reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
    RETVAL=$?
    echo
}

force_reload() {
    restart
}

configtest() {
  $nginx -t -c $NGINX_CONF_FILE
}

rh_status() {
    status $prog
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac
' > /etc/rc.d/init.d/nginx

chmod +x /etc/rc.d/init.d/nginx

auto_service='nginx'
chkconfig --add "${auto_service}"
chkconfig "${auto_service}" on
}

set_logrotate (){
grep -E '^#SET nginx logrotate _END_' /etc/crontab >/dev/null 2>&1 || nginx_set='fail'
if [ "${nginx_set}" = 'fail' ];then
echo '#!/bin/bash

nginx_log_path='/var/log/nginx'
nginx_pid='/var/run/nginx.pid'

if [ ! -d "${nginx_log_path}" ];then
        echo "${nginx_log_path} not exist!please check!" 1>&2
        exit 1
else
        find ${nginx_log_path} -type f -size 0|xargs -r -i rm -f "{}"
fi

if [ ! -f "${nginx_pid}" ];then
        echo "${nginx_pid} not exist!please check!" 1>&2
        exit 1
fi

suffix=`date -d "-1 day" +"%Y-%m-%d"`

for log in `ls /var/log/nginx/*.log|xargs -r -i basename "{}"`
do
        mv ${nginx_log_path}/${log} ${nginx_log_path}/${log}.${suffix}        
done

kill -USR1 `cat ${nginx_pid}` && exit 0' >/etc/nginx/nginx_logrotate.sh
chmod +x /etc/nginx/nginx_logrotate.sh
echo '#SET nginx logrotate _BEGIN_
0 0 * * * root /etc/nginx/nginx_logrotate.sh >/dev/null
#SET nginx logrotate _END_' >>/etc/crontab
fi
}

backup_nginx_conf () {
grep -E '^#SET back nginx conf _END_' /etc/crontab >/dev/null 2>&1 || backup_nginx_conf='fail'
if [ "${backup_nginx_conf}" = 'fail' ];then
echo '#!/bin/bash

day=`date -d "-1 day" +"%Y-%m-%d"`
rm_day=`date -d "-15 day" +"%Y-%m-%d"`
backup_path='/backup/nginx_conf'

mkdir -p ${backup_path} && cd ${backup_path}
tar czf nginx-conf.${day}.tar.gz /etc/nginx/*

test -f "nginx-conf.${rm_day}.tar.gz" && rm -f "nginx-conf.${rm_day}.tar.gz"
' > /etc/nginx/backup_nginx_conf.sh
chmod +x /etc/nginx/backup_nginx_conf.sh
echo '#SET backup nginx conf  _BEGIN_
0 0 * * * root /etc/nginx/backup_nginx_conf.sh >/dev/null
#SET back nginx conf _END_' >>/etc/crontab
fi
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#CREATE nginx user
NGINX_USER='www'
create_user "${NGINX_USER}" "nologin"

#Install nginx-1.5.9.tar.gz
PACKAGE='nginx-1.5.9.tar.gz'
create_tmp_dir
download_and_check
run_cmds "./configure --user=${NGINX_USER} \
        --group=${NGINX_USER} \
        --prefix=/usr/local/nginx \
		--sbin-path=/usr/sbin \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-http_perl_module" 'make' 'make install'

set_auto_run
set_logrotate
backup_nginx_conf

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
