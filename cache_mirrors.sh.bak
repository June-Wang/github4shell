#!/bin/bash

CACHE_SERVER='cache.mirrors.local'
#MIRROR_URL='ftp://ftp.kr.debian.org'

modify_centos_mirror () {
local my_date=`date -d "now" +"%F"`
if [ -d "${SOURCE_DIR}" ];then
        find ${SOURCE_DIR} -type f -name "*.repo"|grep -Ev 'CENTOS5-lan.repo|cache_mirror.repo|RHEL5-lan.repo'|\
        while read source_file
        do
                mv "${source_file}" "${source_file}.${my_date}.$$"
        done
fi

repo_file="${SOURCE_DIR}/cache_mirror.repo"
echo "[base]
name=CentOS-\$releasever - Base
baseurl=http://${CACHE_SERVER}/centos/\$releasever/os/\$basearch/
gpgcheck=0

#released updates 
[updates]
name=CentOS-\$releasever - Updates
baseurl=http://${CACHE_SERVER}/centos/\$releasever/updates/\$basearch/
gpgcheck=0

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
baseurl=http://${CACHE_SERVER}/centos/\$releasever/extras/\$basearch/
gpgcheck=0

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus
baseurl=http://${CACHE_SERVER}/centos/\$releasever/centosplus/\$basearch/
gpgcheck=0

#contrib - packages by Centos Users
[contrib]
name=CentOS-\$releasever - Contrib
baseurl=http://${CACHE_SERVER}/centos/\$releasever/contrib/\$basearch/
gpgcheck=0

[epel]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch
baseurl=http://${CACHE_SERVER}/epel/\$releasever/\$basearch
failovermethod=priority
gpgcheck=0

[epel-source]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Source
baseurl=http://${CACHE_SERVER}/epel/\$releasever/SRPMS
failovermethod=priority
gpgcheck=0

#[epel-testing]
#name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch 
#baseurl=http://${CACHE_SERVER}/epel/testing/\$releasever/\$basearch
#failovermethod=priority
#gpgcheck=0

#[epel-testing-source]
#name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Source
#baseurl=http://${CACHE_SERVER}/epel/testing/\$releasever/SRPMS
#failovermethod=priority
#gpgcheck=0" > ${repo_file}
#yum makecache
}

modify_debian_mirror () {
local source_file="${SOURCE_DIR}/sources.list"
if [ -e ${source_file} ];then
        case "${SYSTEM_INFO}" in
                'Debian GNU/Linux 6'*)
                        DEBIAN_VERSION='squeeze'
                ;;
                'Debian GNU/Linux 5'*)
                        DEBIAN_VERSION='wheezy'
                ;;
                *)
                        echo "This script not support ${SYSTEM_INFO}" 1>&2
                        exit 1
                ;;
        esac
        local my_date=`date -d "now" +"%F"`
        cp "${source_file}" "${source_file}.${my_date}.$$"
        echo "deb http://${CACHE_SERVER}/debian stable main #non-free contrib
deb-src http://${CACHE_SERVER}/debian stable main #non-free contrib
deb http://${CACHE_SERVER}/debian-security ${DEBIAN_VERSION}/updates main
deb-src http://${CACHE_SERVER}/debian-security ${DEBIAN_VERSION}/updates main" > ${source_file}
else
        echo "Can not find ${source_file},please check!" 1>&2
        exit 1
fi
apt_conf_dir="${SOURCE_DIR}/apt.conf.d"
#proxy_conf="${apt_conf_dir}/000apt-cacher-ng-proxy"
#test -d ${apt_conf_dir} && echo "Acquire::http::Proxy \"http://${CACHE_SERVER}:3142/\";" > ${proxy_conf}
find ${apt_conf_dir} -type f |xargs -r grep -l 'Acquire::http::Proxy'|xargs -r -i sed -i '/^Acquire::http::Proxy/d' "{}"
#apt-get update
}

main () {
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS'*)
                SYSTEM='centos'
                SOURCE_DIR='/etc/yum.repos.d'
                modify_centos_mirror
                ;;
        'Debian'*)
                SYSTEM='debian'
                SOURCE_DIR='/etc/apt'
                modify_debian_mirror
        ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                yum_source_name='RHEL5-lan'
                file='/etc/yum.repos.d/RHEL5-lan.repo'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

main
