#!/bin/bash

centos_mirrors='mirrors.aliyun.com'
epel_mirrors='mirrors.aliyun.com'
debian_mirrors='mirrors.aliyun.com'
cache_server='cache.mirrors.local'

#set DNS
echo 'nameserver 192.168.1.201' > /etc/resolv.conf

alias_yum () {
profile_dir='/etc/profile.d'
[ -d "${profile_dir}" ] &&\
yum_para='yum --skip-broken --nogpgcheck'
#echo "alias yum='yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${yum_source_name}'" > ${profile_dir}/yum_alias.sh
echo "alias yum='${yum_para}'" > ${profile_dir}/yum_alias.sh
#alias yum="yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${yum_source_name}"
alias yum="${yum_para}"
}

backup_local_repo_file () {
local my_date=`date -d "now" +"%F"`
if [ -d "${SOURCE_DIR}" ];then
        find ${SOURCE_DIR} -type f -name "*.repo"|grep -Ev 'CENTOS.*-lan.repo|RHEL.*-lan.repo'|\
        while read source_file
        do
                mv "${source_file}" "${source_file}.${my_date}.$$"
        done
fi
}

backup_source_list () {
local source_file="${SOURCE_DIR}/sources.list"
if [ -e ${source_file} ];then
        local my_date=`date -d "now" +"%F"`
        mv "${source_file}" "${source_file}.${my_date}.$$"
else
        echo "Can not find ${source_file},please check!" 1>&2
fi
}

mirrors_for_centos () {
local system_info=`head -n 1 /etc/issue`
case "${system_info}" in
        'CentOS release 5'*)
		local redhat_version='5'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
		local redhat_version='5'
                ;;
        'Red Hat Enterprise Linux Server release 6'*)
		local redhat_version='6'
                ;;
        *)
	echo "This script not support ${system_info}" 1>&2
	exit 1
                ;;
esac
local repo_file="${SOURCE_DIR}/base.mirrors.repo"
echo "[base]
name=CentOS-${redhat_version} - Base - ${centos_mirrors}
failovermethod=priority
baseurl=http://${centos_mirrors}/centos/${redhat_version}/os/\$basearch/
        http://mirrors.aliyuncs.com/centos/${redhat_version}/os/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=os
gpgcheck=1
gpgkey=http://${centos_mirrors}/centos/RPM-GPG-KEY-CentOS-${redhat_version}
 
#released updates 
[updates]
name=CentOS-${redhat_version} - Updates - ${centos_mirrors}
failovermethod=priority
baseurl=http://${centos_mirrors}/centos/${redhat_version}/updates/\$basearch/
        http://mirrors.aliyuncs.com/centos/${redhat_version}/updates/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=updates
gpgcheck=1
gpgkey=http://${centos_mirrors}/centos/RPM-GPG-KEY-CentOS-${redhat_version}
 
#additional packages that may be useful
[extras]
name=CentOS-${redhat_version} - Extras - ${centos_mirrors}
failovermethod=priority
baseurl=http://${centos_mirrors}/centos/${redhat_version}/extras/\$basearch/
        http://mirrors.aliyuncs.com/centos/${redhat_version}/extras/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=extras
gpgcheck=1
gpgkey=http://${centos_mirrors}/centos/RPM-GPG-KEY-CentOS-${redhat_version}
 
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-${redhat_version} - Plus - ${centos_mirrors}
failovermethod=priority
baseurl=http://${centos_mirrors}/centos/${redhat_version}/centosplus/\$basearch/
        http://mirrors.aliyuncs.com/centos/${redhat_version}/centosplus/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=http://${centos_mirrors}/centos/RPM-GPG-KEY-CentOS-${redhat_version}
 
#contrib - packages by Centos Users
[contrib]
name=CentOS-${redhat_version} - Contrib - ${centos_mirrors}
failovermethod=priority
baseurl=http://${centos_mirrors}/centos/${redhat_version}/contrib/\$basearch/
        http://mirrors.aliyuncs.com/centos/${redhat_version}/contrib/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=contrib
gpgcheck=1
enabled=0
gpgkey=http://${centos_mirrors}/centos/RPM-GPG-KEY-CentOS-${redhat_version}" > ${repo_file}
}

mirrors_for_epel () {
local repo_file="${SOURCE_DIR}/epel.mirrors.repo"
echo "[epel]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch
baseurl=http://${epel_mirrors}/epel/\$releasever/\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=http://${epel_mirrors}/epel/RPM-GPG-KEY-EPEL

[epel-debuginfo]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Debug
baseurl=http://${epel_mirrors}/epel/\$releasever/\$basearch/debug
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/epel/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Source
baseurl=http://${epel_mirrors}/epel/\$releasever/SRPMS
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/epel/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-testing]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch 
baseurl=http://${epel_mirrors}/epel/testing/\$releasever/\$basearch
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=http://${epel_mirrors}/epel/RPM-GPG-KEY-EPEL

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Debug
baseurl=http://${epel_mirrors}/epel/testing/\$releasever/\$basearch
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/epel/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Source
baseurl=http://${epel_mirrors}/epel/testing/\$releasever/SRPMS
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/epel/RPM-GPG-KEY-EPEL
gpgcheck=1" > ${repo_file}
}

mirrors_for_debian () {
local source_file="${SOURCE_DIR}/sources.list"
debian_release=`echo "${SYSTEM_INFO}" |\
cat /etc/issue|head -n1|grep -oE '[0-9]+'|head -n1`
case "${debian_release}" in
        7)
                DEBIAN_VERSION='wheezy'
                DEBIAN_ISSUE='7'
        ;;
        6)
                DEBIAN_VERSION='squeeze'
                DEBIAN_ISSUE='6'
        ;;
        *)
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac

backup_source_list

echo "deb http://${debian_mirrors}/debian/ ${DEBIAN_VERSION} main non-free contrib
deb http://${debian_mirrors}/debian/ ${DEBIAN_VERSION}-proposed-updates main non-free contrib
deb-src http://${debian_mirrors}/debian/ ${DEBIAN_VERSION} main non-free contrib
deb-src http://${debian_mirrors}/debian/ ${DEBIAN_VERSION}-proposed-updates main non-free contrib" > ${source_file}

apt_path='/etc/apt/sources.list.d'
if [ "${DEBIAN_VERSION}" == 'wheezy' ];then
        test -d ${apt_path} &&\
        echo "deb http://debian.saltstack.com/debian wheezy-saltstack main" > ${apt_path}/salt.list
fi

if [ "${DEBIAN_VERSION}" == 'squeeze' ];then
        test -d ${apt_path} &&\
        echo "deb http://debian.saltstack.com/debian squeeze-saltstack main
deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free" > ${apt_path}/salt.list
fi

local apt_conf_d='/etc/apt/apt.conf.d'
local apt_conf="${apt_conf_d}/00trustlocal"
test -d ${apt_conf_d} || mkdir -p ${apt_conf_d}
echo 'Aptitude::Cmdline::ignore-trust-violations "true";' > ${apt_conf}
}

set_proxy_for_debian () {
local apt_conf_d='/etc/apt/apt.conf.d'
local proxy_conf="${apt_conf_d}/02proxy"
test -d ${apt_conf_d} &&\
echo 'Acquire::http { Proxy "http://'${cache_server}':3142"; };' > ${proxy_conf}
}

set_proxy_for_redhat () {
local yum_conf='/etc/yum.conf'
if [ -f "${yum_conf}" ];then
	sed -i '/^proxy/d' ${yum_conf} 
	echo "proxy=http://${cache_server}:3142" >> ${yum_conf}
fi
}

set_for_redhat () {
backup_local_repo_file
mirrors_for_centos
mirrors_for_epel
set_proxy_for_redhat
alias_yum
yum clean all
}

alias_apt () {
local apt_conf_d='/etc/apt/apt.conf.d'
local apt_conf="${apt_conf_d}/00trustlocal"
test -d ${apt_conf_d} || mkdir -p ${apt_conf_d}
echo 'Aptitude::Cmdline::ignore-trust-violations "true";' > ${apt_conf}
#aptitude update
}

main () {
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
'CentOS'*)
        SYSTEM='centos'
        SOURCE_DIR='/etc/yum.repos.d'
        set_for_redhat
        ;;
'Red Hat Enterprise Linux Server release'*)
        SYSTEM='rhel'
        SOURCE_DIR='/etc/yum.repos.d'
        set_for_redhat
        ;;
'Debian'*)
        SYSTEM='debian'
        SOURCE_DIR='/etc/apt'
        mirrors_for_debian
	alias_apt
	set_proxy_for_debian
	aptitude update
        ;;
*)
        SYSTEM='unknown'
        echo "This script not support ${SYSTEM_INFO}"1>&2
        exit 1
        ;;
esac
}

main
