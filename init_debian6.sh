#!/bin/bash

yum_server='yum.suixingpay.com'
ntp_server='ntp.suixingpay.local'

#set DNS
echo 'nameserver 192.168.29.230
nameserver 192.168.29.229' > /etc/resolv.conf

#install package
echo -n "Install sysv-rc-conf vim htop ... "
aptitude install -y sysv-rc-conf vim htop >/dev/null 2>&1 || install_package='fail' && echo 'done.'
if [ "${install_package}" = "fail" ];then
        echo "Install sysv-rc-conf vim fail! Please check aptitude!" 1>&2
        exit 1
fi

#set vim for python
grep -E '^#SET VIM' /etc/vimrc >/dev/null 2>&1 || echo "#SET VIM
set ts=4" >> /etc/vimrc

#set ntp
echo -n "Set ntp ... "
aptitude -y install ntpdate >/dev/null 2>&1 || install_ntp='fail'
if [ "${install_ntp}" = "fail" ];then
        echo "Install ntpdate fail! Please check aptitude!" 1>&2
        exit 1
else
        grep 'ntpdate' /etc/crontab >/dev/null 2>&1 || ntp_set='no'
        if [ "${ntp_set}" = "no" ];then
#                /usr/sbin/ntpdate ${ntp_server} >/dev/null 2>&1
                echo "*/15 * * * * root ntpdate ${ntp_server} > /dev/null 2>&1" >> /etc/crontab
                echo 'done.'
        fi
fi

#global
echo -n "set global.sh to /etc/profile.d/ ... "
if [ -d "/etc/profile.d/" ];then
        cd /etc/profile.d
        if [ ! -e global.sh ];then
                wget -q http://${yum_server}/shell/global.sh || install_env='fail'
                if [ "${install_env}" = "fail" ];then
                        echo "http://${yum_server}/shell/global.sh not exist!" 1>&2
                        exit 1
                fi
        fi
else
        echo "/etc/profile.d/ not exist!" 1>&2
        exit 1
fi
echo 'done.'

#tunoff services
sysv-rc-conf --list|awk '/:on/{print $1}'|grep -E 'nfs-common|portmap|exim4|rpcbind'|\
while read line
do
        sysv-rc-conf "${line}" off
        service "${line}" stop >/dev/null 2>&1
        echo "service ${line} stop"
done

#set sshd
sshd_config='/etc/ssh/sshd_config'
test -e ${sshd_config} && sshd_service='true'
if [ "${sshd_service}" = 'true' ];then
	echo "set service sshd.modify ${sshd_config}"
	grep 'UseDNS' ${sshd_config} || echo "UseDNS no" >> ${sshd_config} && \
	sed -i -r 's/^UseDNS.*/UseDNS no/g' ${sshd_config}
	/etc/init.d/ssh restart
fi

echo "init service ok."
