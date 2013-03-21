#!/bin/bash

check_system (){
system_info=`head -n 1 /etc/issue`
case "${system_info}" in
        'CentOS release 5'*) 
		system='centos5'
		yum_source_name='centos5-lan'
		repo_file='/etc/yum.repos.d/CENTOS5-lan.repo'
		;;
        'Red Hat Enterprise Linux Server release 5'*) 
		system='rhel5'
		yum_source_name='RHEL5-lan'
		repo_file='/etc/yum.repos.d/RHEL5-lan.repo'
		;;
        *) 
		system='unknown'
		echo "This script not support ${system_info}" 1>&2
		exit 1
		;;
esac
}

check_repo_config () {
#Detect repo configuration
grep -E "${yum_source_name}" >/dev/null 2>&1 ${repo_file} && set_yum='ok'
[ "${set_yum}" = 'ok' ] && exit 0
}

check_platform () {
platform_info=`uname -m`
echo ${platform_info}|grep '64' >/dev/null 2>&1 && platform='x64' || platform='x86'
}

set_repo_file () {
#check operating system and set yum local repo 
case "${system}" in
rhel5)
echo "[RHEL5-lan]
name=Red Hat Enterprise Linux \$releasever - \$basearch
baseurl=http://${yum_server}/rhel5.8_${platform}/Server/
gpgcheck=0" > ${repo_file}
;;
centos5)
echo "[centos5-lan]
name=CentOS-\$releasever - Media
baseurl=http://${yum_server}/centos5.8_${platform}/
gpgcheck=0" > ${repo_file}
;;
esac
}

alias_yum () {
profile_dir='/etc/profile.d'
[ -d "${profile_dir}" ] &&\
echo "alias yum='yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${yum_source_name}'" > ${profile_dir}/yum_alias.sh
alias yum="yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${yum_source_name}"
}

set_dns_server () {
dns_config='/etc/resolv.conf'
if [ -e ${dns_config} ];then
        grep '192.168.29.230' ${dns_config} >/dev/null 2>&1 || echo 'nameserver 192.168.29.230' >> ${dns_config}
fi
}

set_yum_proxy () {
yum_config='/etc/yum.conf'
if [ -e ${yum_config} ];then
	grep -E '^proxy*' ${yum_config} >/dev/null 2>&1 &&\
	sed -r -i "s/^proxy.*$/proxy=http:\/\/${yum_server}:80\//" ${yum_config} ||\
	echo "proxy=http://${yum_server}:80/" >> ${yum_config}
fi
}

clean_yum_cache () {
yum clean all
#yum makecache |tail -n 1 && exit 0
}

main () {
yum_server='yum.suixingpay.com'
check_system
#check_repo_config
check_platform
#echo "Set yum please wait ......"
set_repo_file
alias_yum
set_dns_server
#set_yum_proxy
clean_yum_cache
echo "Done."
}

main
