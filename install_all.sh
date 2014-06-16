#!/bin/bash

check_system (){
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
		INIT_SCRIPT='init_centos5.sh'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
		INIT_SCRIPT='init_centos5.sh'
                ;;
        'Debian GNU/Linux 6'*)
                SYSTEM='debian6'
		INIT_SCRIPT='init_debian6.sh'
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

#http server
#http_server='yum.suixingpay.com'
http_server='192.168.29.234'
url="http://${http_server}/shell"

#print error
fail () {
	value=$1
	message=$2
	if [ "${value}" = "fail" ];then
		echo "$2" 1>&2
		exit 1
	fi
}

files=('yum_local.sh' "${INIT_SCRIPT}" 'install_nagios.sh' 'install_snmp.sh' 'modify_syslog.sh')
for file in "${files[@]}"
do
	message=`echo "${file}"|sed 's/sh$/ /g;s/_/ /g'`
	echo "${message} ..."
	sleep 1
	wget -q "${url}/${file}" || case='fail'
	fail "${case}" "${url}/${file} not exist!"
	sh "${file}"
	[ -f "${file}" ] && rm -f "${file}"
done
