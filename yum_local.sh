#!/bin/bash

yum_server='yum.suixingpay.com'

check_system (){
system_info=`head -n 1 /etc/issue`
case "${system_info}" in
        'CentOS release 5'*) 
		system='centos5'
		yum_source_name='centos5-lan'
		file='/etc/yum.repos.d/CENTOS5-lan.repo'
		;;
        'Red Hat Enterprise Linux Server release 5'*) 
		system='rhel5'
		yum_source_name='RHEL5-lan'
		file='/etc/yum.repos.d/RHEL5-lan.repo'
		;;
        *) 
		system='unknown'
		echo "This script not support ${system_info}" 1>&2
		exit 1
		;;
esac
}

check_system

grep -E "${yum_source_name}" >/dev/null 2>&1 ${file} && set_yum='ok'
[ "${set_yum}" = 'ok' ] && exit 0

echo "set yum please wait ......"
platform_info=`uname -m`
echo ${platform_info}|grep '64' >/dev/null 2>&1 && platform='x64' || platform='x86'

profile_dir='/etc/profile.d'
case "${system}" in
rhel5)
echo "[RHEL5-lan]
name=Red Hat Enterprise Linux \$releasever - \$basearch
baseurl=http://${yum_server}/rhel5.8_${platform}/Server/
gpgcheck=0" > ${file}
;;
centos5)
echo "[centos5-lan]
name=CentOS-\$releasever - Media
baseurl=http://${yum_server}/centos5.8_${platform}/
gpgcheck=0" > ${file}
;;
esac

[ -d "${profile_dir}" ] && echo "alias yum='yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${yum_source_name}'" > ${profile_dir}/yum_alias.sh
alias yum="yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${yum_source_name}"

if [ -e /etc/hosts ];then
        grep 'yum.suixingpay.com' /etc/hosts >/dev/null 2>&1 || echo '192.168.29.234 yum.suixingpay.com' >> /etc/hosts
fi
yum makecache |tail -n 1 && exit 0
