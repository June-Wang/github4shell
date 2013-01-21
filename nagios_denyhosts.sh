#!/bin/bash

yum_server='192.168.29.234'
nagios_plugin='check_denyhosts.sh'
nagios_cfg='/usr/local/nagios/etc/nrpe.cfg'
nagios_lib='/usr/local/nagios/libexec'

if [ -e ${nagios_cfg} ];then
	test -d ${nagios_lib} && cd ${nagios_lib} || eval "echo ${nagios_lib} not exsit!;exit 1"	
	wget -q "http://${yum_server}/shell/${nagios_plugin}" || eval "echo download http://${yum_server}/shell/${nagios_plugin} fail!;exit 1"
	test -e "${nagios_lib}/${nagios_plugin}" && chmod +x "${nagios_lib}/${nagios_plugin}"
	grep 'check_denyhosts' ${nagios_cfg} >/dev/null 2>&1 || nagios='notset'
	if [ "${nagios}" = 'notset' ];then
		echo "command[check_denyhosts]=${nagios_lib}/${nagios_plugin}" >> ${nagios_cfg}
	fi
fi
