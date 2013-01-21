#!/bin/bash

init_var () {
#set yum server
yum_server="$1"
file_name="$2"
yum_para="$3"
if [ "${yum_para}" = 'lan' ];then
	YUM='yum --disablerepo=\* --enablerepo=centos5-lan'
else
	YUM='yum'
fi
package_url="http://${yum_server}/tools/${file_name}"
}

create_nginx_user () {
	grep 'nginx' /etc/passwd >/dev/null 2>&1 && userdel nginx
	useradd -M -c "Nginx user" -s /bin/false -r -d /usr/local/nginx nginx
}

install_lib () {
log_name="$1"
log_file="${local_path}/yum_for_${log_name}.log"
echo -n "install gcc openssl glib2 pcre bzip gzip please wait ......"
eval "${YUM} install -y gcc gcc-c++ openssl openssl-devel glib2-devel pcre-devel bzip2-devel gzip-devel >${log_file} 2>&1" || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!view error please type: less ${log_file}" 1>&2
        exit 1
fi
echo "done."
}

make_dir () {
mkdir -p "${local_path}/${install_dir}" && cd "${local_path}/${install_dir}" || mkdir_dir='fail'
if [ "${mkdir_dir}" = "fail"  ];then
        echo "mkdir ${install_dir} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
#del tmp file
test -d "${local_path}/${install_dir}" && rm -rf "${local_path}/${install_dir}"
}

check_urls () {
for url in "$@"
do
        file=`echo ${url}|awk -F'/' '{print $NF}'`
        if [ ! -f "${file}" ]; then
                echo -n "download ${url} ..."
                wget -q "${url}"  && echo 'done.' || download='fail'
                if [ "${download}" = "fail" ];then
                        echo "download ${url} fail!" 1>&2 && del_tmp
                        exit 1
                fi
        fi
done
}

install_pre () {
        install_url="$1"
        file=`echo ${install_url}|awk -F'/' '{print $NF}'`
        dir=`echo ${file}|awk -F'.tar' '{print $1}'`
        test -e "${file}" && tar xzf ${file} || tar_file='not_exist'
        cd ${dir} || file_dir='not_exist'
        if [ "${tar_file}" = 'not_exist' ];then
                echo "${file} not exist!" 1>&2 && del_tmp
                exit 1
        fi
        if [ "${file_dir}" = 'not_exist' ];then
                echo "plesse check ${file}!" 1>&2 && del_tmp
                exit 1
        fi
        echo -n "Compile ${dir} please wait ...... "
}

run_cmds () {
        cmd_log="${local_path}/install_${dir}.log"
        test -f "${cmd_log}" && cat /dev/null > "${local_path}/install_${dir}.log"
        for cmd in "$@"
        do
                ${cmd} >> "${cmd_log}" 2>&1 || compile='fail'
                if [ "${compile}" = 'fail' ]; then
                        echo "run ${cmd} error! please type: less ${cmd_log}" 1>&2 && del_tmp
                        exit 1
                fi
        done
        echo "done."
}

install_nginx () {
	install_pre "${package_url}"
	./configure --user=nginx \
        --group=nginx \
        --prefix=/usr/local/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/subsys \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-http_perl_module \
        --with-mail \
        --with-mail_ssl_module >> ${local_path}/install_${dir}.log 2>&1 || configure='fail'
	if [ "${configure}" = 'fail' ]; then
                        echo "run ./configure error! please type: less ${local_path}/install_${dir}.log" 1>&2 && del_tmp
                        exit 1
                fi
	run_cmds 'make' 'make install'
	#test -d /var/lock/subsys/nginx || mkdir -p /var/lock/subsys/nginx
	cd ..
}

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

auto_service="$1"
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
0 7 * * * root /etc/nginx/nginx_logrotate.sh >/dev/null
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
' >/etc/nginx/backup_nginx_conf.sh
chmod +x /etc/nginx/backup_nginx_conf.sh
echo '#SET backup nginx conf  _BEGIN_
0 0 * * * root /etc/nginx/backup_nginx_conf.sh >/dev/null
#SET back nginx conf _END_' >>/etc/crontab
fi
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete! Please type : /etc/init.d/nginx start " && exit 0
}

main () {
my_project='nginx'
init_var 'yum.suixingpay.com' 'nginx-1.2.1.tar.gz' 'lan'
install_lib "${my_project}"
make_dir
check_urls "${package_url}"
create_nginx_user
install_nginx
set_auto_run "${my_project}"
set_logrotate
backup_nginx_conf
del_tmp
echo_bye "${my_project}"
}

#local install path
local_path='/usr/local/src'
install_dir="install_$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${install_dir}"  EXIT
main
