#!/bin/bash

CACHE_SERVER='cache.mirrors.local'

backup_local_repo_file () {
local my_date=`date -d "now" +"%F"`
if [ -d "${SOURCE_DIR}" ];then
        find ${SOURCE_DIR} -type f -name "*.repo"|grep -Ev 'CENTOS5-lan.repo|RHEL5-lan.repo'|\
        while read source_file
        do
                mv "${source_file}" "${source_file}.${my_date}.$$"
        done
fi
}

modify_centos_mirror () {
repo_file="${SOURCE_DIR}/cache_mirror.repo"
echo "[base]
name=CentOS-\$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[updates]
name=CentOS-\$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=updates
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[extras]
name=CentOS-\$releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=extras
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[centosplus]
name=CentOS-\$releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[contrib]
name=CentOS-\$releasever - Contrib
mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=contrib
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[epel]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-\$releasever&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL

[epel-debuginfo]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Debug
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-debug-\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux \$releasever - \$basearch - Source
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-testing]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch 
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=testing-epel\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Debug
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=testing-debug-epel\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux \$releasever - Testing - \$basearch - Source
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
gpgcheck=1" > ${repo_file}
#yum makecache
}

modify_rhel5_mirror () {
repo_file="${SOURCE_DIR}/cache_mirror.repo"
echo "[base]
name=CentOS-${releasever} - Base
mirrorlist=http://mirrorlist.centos.org/?release=${releasever}&arch=\$basearch&repo=os
#gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
gpgcheck=0

[updates]
name=CentOS-${releasever} - Updates
mirrorlist=http://mirrorlist.centos.org/?release=${releasever}&arch=\$basearch&repo=updates
#gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
gpgcheck=0

[extras]
name=CentOS-${releasever} - Extras
mirrorlist=http://mirrorlist.centos.org/?release=${releasever}&arch=\$basearch&repo=extras
#gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
gpgcheck=0

[centosplus]
name=CentOS-${releasever} - Plus
mirrorlist=http://mirrorlist.centos.org/?release=${releasever}&arch=\$basearch&repo=centosplus
#gpgcheck=1
enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
gpgcheck=0

[contrib]
name=CentOS-${releasever} - Contrib
mirrorlist=http://mirrorlist.centos.org/?release=${releasever}&arch=\$basearch&repo=contrib
#gpgcheck=1
enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
gpgcheck=0

[epel]
name=Extra Packages for Enterprise Linux ${releasever} - $basearch
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${releasever}&arch=$basearch
failovermethod=priority
enabled=1
#gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
gpgcheck=0

[epel-debuginfo]
name=Extra Packages for Enterprise Linux ${releasever} - $basearch - Debug
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-debug-${releasever}&arch=$basearch
failovermethod=priority
enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
#gpgcheck=1
gpgcheck=0

[epel-source]
name=Extra Packages for Enterprise Linux ${releasever} - $basearch - Source
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-${releasever}&arch=$basearch
failovermethod=priority
enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
#gpgcheck=1
gpgcheck=0" > ${repo_file}
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
				backup_local_repo_file
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
				releasever='5'
#                echo "This script not support ${SYSTEM_INFO}" 1>&2
#                exit 1
				backup_local_repo_file
				modify_rhel5_mirror
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

main
