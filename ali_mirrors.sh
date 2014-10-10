#!/bin/bash

epel_mirrors='epel.mirrors.local'
debian_mirrors='debian.mirrors.local'
cache_server='cache.mirrors.local'

#set DNS
echo 'nameserver 192.168.16.22' > /etc/resolv.conf

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

mirrors_for_epel () {
local repo_file="${SOURCE_DIR}/epel.mirrors.repo"
echo "[epel]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch
baseurl=http://${epel_mirrors}/\$releasever/\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL

[epel-debuginfo]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Debug
baseurl=http://${epel_mirrors}/\$releasever/\$basearch/debug
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Source
baseurl=http://${epel_mirrors}/epel/\$releasever/SRPMS
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-testing]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch 
baseurl=http://${epel_mirrors}/testing/\$releasever/\$basearch
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Debug
baseurl=http://${epel_mirrors}/testing/\$releasever/\$basearch
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Source
baseurl=http://${epel_mirrors}/epel/testing/\$releasever/SRPMS
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL
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

local apt_conf_d='/etc/apt/apt.conf.d'
local proxy_conf="${apt_conf_d}/02proxy"
test -f ${proxy_conf} ||\
echo 'Acquire::http { Proxy "http://'${cache_server}':3142"; };' > ${proxy_conf}

local apt_conf="${apt_conf_d}/00trustlocal"
test -d ${apt_conf_d} || mkdir -p ${apt_conf_d}
echo 'Aptitude::Cmdline::ignore-trust-violations "true";' > ${apt_conf}
aptitude update
}

set_for_redhat () {
backup_local_repo_file
mirrors_for_epel
yum clean all
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
        ;;
*)
        SYSTEM='unknown'
        echo "This script not support ${SYSTEM_INFO}"1>&2
        exit 1
        ;;
esac
}

main
