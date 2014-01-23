#!/bin/bash

#log server
syslog_server='syslog.suixingpay.local'

#yum server
yum_server='yum.suixingpay.com'

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
        *)
                system='unknown'
                echo "This script not support ${system_info}" 1>&2
                exit 1
                ;;
esac

#stop syslog
test -e /etc/init.d/syslog && eval "/etc/init.d/syslog stop;chkconfig syslog off"

#alias yum local
alias yum="yum --disablerepo=\* --enablerepo=${yum_source_name}"

#install rsyslog
rsyslog_config='/etc/rsyslog.conf'
if [ -e "${rsyslog_config}" ];then
	echo "rsyslog has been installed!"
else	
	yum -y install rsyslog || install_rsyslog='fail'
	if [ "${install_rsyslog}" = "fail" ];then
        	echo "yum not available! install rsyslog fail!" 1>&2
	        exit 1
	fi
	chkconfig rsyslog on
fi

#set rsyslog config
grep -E '^#MODIFY SYSLOG CONFIG' ${rsyslog_config} >/dev/null 2>&1 || rsyslog_status='not set'
if [ "${rsyslog_status}" = 'not set' ];then
	sed '/^\$ActionFileDefaultTemplate/d' ${rsyslog_config}
	echo "#MODIFY SYSLOG CONFIG
# Use default timestamp format
\$template myformat,\"%\$NOW% %TIMESTAMP% %hostname% %syslogtag% %msg%\n\"
\$ActionFileDefaultTemplate myformat
#record history log 
local4.=debug                  -/var/log/history.log 
#log to syslog server 
*.*            @${syslog_server}" >> ${rsyslog_config}

if [ "${MODIFY_SYSCONFIG}" = 'true' ];then
        if [ -e /etc/sysconfig/rsyslog ];then
                sed -i -r 's/^(SYSLOGD_OPTIONS).*/\1=\"-c 3\"/' /etc/sysconfig/rsyslog
        fi
fi

/etc/init.d/rsyslog restart
else
	echo "${rsyslog_config} has been configured!"
fi

#set get_history script
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
