#!/bin/bash

#log server
syslog_server='syslog.suixingpay.local'

#yum server
yum_server='yum.suixingpay.com'

check_system () {
system_info=`head -n 1 /etc/issue`
case "${system_info}" in
        'CentOS release 5'*)
                system='centos5'
                yum_source_name='centos5-lan'
				MODIFY_SYSCONFIG='true'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                system='rhel5'
                yum_source_name='RHEL5-lan'
				MODIFY_SYSCONFIG='true'
                ;;
        'Red Hat Enterprise Linux Server release 6'*)
                system='rhel6'
                yum_source_name='RHEL6-lan'
				MODIFY_SYSCONFIG='true'
                ;;
        *)
                system='unknown'
                echo "This script not support ${system_info}" 1>&2
                exit 1
                ;;
esac
}

stop_syslogd () {
test -e /etc/init.d/syslog && chkconfig syslog off
pgrep syslogd >/dev/null 2>&1 && /etc/init.d/syslog stop
}

alias_yum () {
alias yum="yum --disablerepo=\* --enablerepo=${yum_source_name}"
}

install_rsyslog () {
rsyslog_config='/etc/rsyslog.conf'
rsyslog_init='/etc/init.d/rsyslog'
if [ -e "${rsyslog_init}" ];then
	echo "rsyslog has been installed!"
else	
	yum -y install rsyslog || install_rsyslog='fail'
	if [ "${install_rsyslog}" = "fail" ];then
        	echo "yum not available! install rsyslog fail!" 1>&2
	        exit 1
	fi
	chkconfig rsyslog on
fi
}

setting_rsyslog_config () {
grep -E '^#MODIFY SYSLOG CONFIG' ${rsyslog_config} >/dev/null 2>&1 || rsyslog_status='not set'
if [ "${rsyslog_status}" = 'not set' ];then
	sed -i.bak.`date -d now +"%F_%H-%M"` -r 's/\$ActionFileDefaultTemplate.*/#&/' ${rsyslog_config}
	echo "#MODIFY SYSLOG CONFIG
# Use default timestamp format
\$template myformat,\"%\$NOW% %TIMESTAMP% %hostname% %syslogtag% %msg%\n\"
\$ActionFileDefaultTemplate myformat
#record history log 
local4.=debug                  -/var/log/history.log 
#log to syslog server 
*.*            @${syslog_server}" >> ${rsyslog_config}
else
	echo "${rsyslog_config} has been configured!"
fi
}

modify_rsyslog_config () {
if [ "${MODIFY_SYSCONFIG}" = 'true' ];then
        if [ -e /etc/sysconfig/rsyslog ];then
				time_now=`date -d now +"%F_%H-%M"`
                sed -i.bak.${time_now} -r 's/^(SYSLOGD_OPTIONS).*/\1=\"-c5\"/' /etc/sysconfig/rsyslog
        fi
fi
}

restart_rsyslog () {
/etc/init.d/rsyslog restart
}

setting_get_history () {
his_file="http://${yum_server}/shell/get_history.sh"
cd /sbin
wget -q ${his_file} || wget_history='fail'

if [ "${wget_history}" = 'fail' ];then
	echo "download ${his_file} fail!" 1>&2
	exit 1
fi

test -e "/sbin/get_history.sh" && chmod +x /sbin/get_history.sh

grep -E '^#GET HISTORY' /etc/crontab >/dev/null 2>&1 || get_history='not set'
if [ "${get_history}" = 'not set' ];then
	echo '#GET HISTORY
*/5 * * * * root /sbin/get_history.sh >/dev/null' >>/etc/crontab
else
	echo "get_history.sh has been configured!"
fi
}

main () {
check_system
stop_syslogd
alias_yum
install_rsyslog
setting_rsyslog_config
modify_rsyslog_config
restart_rsyslog
setting_get_history
}

main
