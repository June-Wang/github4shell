#!/bin/bash

check_system (){
ls /usr/bin/yum >/dev/null 2>&1 && SYSTEM='redhat'
ls /usr/bin/apt-get >/dev/null 2>&1 && SYSTEM='debian'
}

set_install_cmd () {
case "${SYSTEM}" in
        redhat)
                INSTALL_CMD='yum --skip-broken --nogpgcheck'
                CONFIG_CMD='chkconfig'
                MODIFY_SYSCONFIG='true'
        ;;
        debian)
                INSTALL_CMD='aptitude'
                CONFIG_CMD='chkconfig'
                eval "${INSTALL_CMD} install -y ${CONFIG_CMD}" >/dev/null 2>&1 || eval "echo ${install_cmd} fail! 1>&2;exit 1"
        ;;
        *)
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac
}

install_rsyslog () {
if [ -e /etc/init.d/syslog ];then
        /etc/init.d/syslog status >/dev/null 2>&1 && /etc/init.d/syslog stop >/dev/null 2>&1
        eval "${CONFIG_CMD} syslog off"
fi

if [ ! -e /etc/init.d/rsyslog ];then
       eval "${INSTALL_CMD} install -y rsyslog"
fi

log_profile='etc/rsyslog.d/rsyslog.format.conf'
test -d /etc/rsyslog.d/ &&\
echo 'local4.=debug                                           -/var/log/history.log
#SET Standard timestamp
$template myformat,"%$NOW% %TIMESTAMP:8:15% %HOSTNAME% %syslogtag% %msg%\n"
$ActionFileDefaultTemplate myformat
#log to syslog server' > ${log_profile}
echo "*.*            @${log_server}" >> ${log_profile}

if [ "${MODIFY_SYSCONFIG}" = 'true' ];then
        if [ -e /etc/sysconfig/rsyslog ];then
                sed -i -r 's/^(SYSLOGD_OPTIONS).*/\1=\"-c 3\"/' /etc/sysconfig/rsyslog
        fi
fi
/etc/init.d/rsyslog restart
eval "${CONFIG_CMD} rsyslog on"
}

set_history () {
local his_file='/usr/sbin/get_history.sh'
if [ ! -e "${his_file}" ];then
        test -d /usr/sbin && cd /usr/sbin || exit 1
        wget -q http://${yum_server}/shell/get_history.sh
        chmod +x ${his_file}
fi

grep 'get_history.sh' /etc/crontab >/dev/null 2>&1 || echo "*/5 * * * * root ${his_file} >/dev/null" >>/etc/crontab
}

main () {
yum_server='yum.server.local'
log_server='syslog.server.local'
check_system
set_install_cmd
install_rsyslog
set_history
}

main
