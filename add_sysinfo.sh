#!/bin/bash

yum_server='10.54.1.100'

#add sysinfo
grep 'cron_sysinfo.sh' /etc/crontab >/dev/null 2>&1 || cron_sysinfo_set='no'
if [ "${cron_sysinfo_set}" = "no" ];then
        sysinfo_shell='/usr/sbin/cron_sysinfo.sh'
		test -f ${sysinfo_shell} && rm -f ${sysinfo_shell}
        wget -q http://${yum_server}/shell/cron_sysinfo.sh -O ${sysinfo_shell} ||\
        echo "Download cron_sysinfo.sh fail!" &&\
        echo "* * * * * root ${sysinfo_shell} > /dev/null 2>&1" >> /etc/crontab
        test -f ${sysinfo_shell} && chmod +x ${sysinfo_shell}
fi
