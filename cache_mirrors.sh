#!/bin/bash

#CACHE_SERVER='cache.mirrors.local'
proxy_server='cache.mirrors.local'
proxy_port=3142

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
}

modify_rhel_mirror () {
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
name=Extra Packages for Enterprise Linux ${releasever} - \$basearch
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${releasever}&arch=\$basearch
failovermethod=priority
enabled=1
#gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
gpgcheck=0

[epel-debuginfo]
name=Extra Packages for Enterprise Linux ${releasever} - \$basearch - Debug
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-debug-${releasever}&arch=\$basearch
failovermethod=priority
enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
#gpgcheck=1
gpgcheck=0

[epel-source]
name=Extra Packages for Enterprise Linux ${releasever} - \$basearch - Source
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-${releasever}&arch=\$basearch
failovermethod=priority
enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
#gpgcheck=1
gpgcheck=0" > ${repo_file}
}

check_debian_version () {
debian_release=`echo "${SYSTEM_INFO}" |\
grep -oP 'Debian GNU/Linux\s+\d+'|awk '{print $NF}'`
case "${debian_release}" in
                6)
                        DEBIAN_VERSION='squeeze'
                ;;
                5)
                        DEBIAN_VERSION='wheezy'
                ;;
                *)
                        echo "This script not support ${SYSTEM_INFO}" 1>&2
                        exit 1
                ;;
esac
}

modify_debian_mirror () {
local source_file="${SOURCE_DIR}/sources.list"
if [ -e ${source_file} ];then
        local my_date=`date -d "now" +"%F"`
        cp "${source_file}" "${source_file}.${my_date}.$$"
#        echo "deb http://${CACHE_SERVER}/debian stable main #non-free contrib
#deb-src http://${CACHE_SERVER}/debian stable main #non-free contrib
#deb http://${CACHE_SERVER}/debian-security ${DEBIAN_VERSION}/updates main
#deb-src http://${CACHE_SERVER}/debian-security ${DEBIAN_VERSION}/updates main" > ${source_file}
		echo "deb http://cdn.debian.net/debian/ ${DEBIAN_VERSION} main
deb-src http://cdn.debian.net/debian/ ${DEBIAN_VERSION} main
deb http://cdn.debian.net/debian/ ${DEBIAN_VERSION}-updates main contrib
deb-src http://cdn.debian.net/debian/ ${DEBIAN_VERSION}-updates main contrib" > ${source_file}
else
        echo "Can not find ${source_file},please check!" 1>&2
        exit 1
fi

#set conf var
apt_conf_dir="${SOURCE_DIR}/apt.conf.d"
proxy_conf="${apt_conf_dir}/000apt-cacher-ng-proxy"

#add proxy setting
test -d ${apt_conf_dir} && echo "Acquire::http::Proxy \"http://${proxy_server}:3142/\";" > ${proxy_conf}

#del proxy setting
#find ${apt_conf_dir} -type f |xargs -r grep -l 'Acquire::http::Proxy'|xargs -r -i sed -i '/^Acquire::http::Proxy/d' "{}"
apt-get update
}

check_rhel_version () {
releasever=`echo "${SYSTEM_INFO}" |\
grep -oP 'Red Hat Enterprise Linux Server release\s+\d+'|awk '{print $NF}'`
}

set_yum_proxy () {
yum_config='/etc/yum.conf'
if [ -e ${yum_config} ];then
    grep -E '^proxy*' ${yum_config} >/dev/null 2>&1 &&\
    sed -r -i "s/^proxy.*$/proxy=http:\/\/${proxy_server}:${proxy_port}\//" ${yum_config} ||\
    echo "proxy=http://${proxy_server}:${proxy_port}/" >> ${yum_config}
fi
}

main () {
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS'*)
                SYSTEM='centos'
                SOURCE_DIR='/etc/yum.repos.d'
				backup_local_repo_file
                modify_centos_mirror
				yum clean all
                ;;
        'Debian'*)
                SYSTEM='debian'
                SOURCE_DIR='/etc/apt'
				check_debian_version
                modify_debian_mirror
        ;;
        'Red Hat Enterprise Linux Server release'*)
                SYSTEM='rhel'
                SOURCE_DIR='/etc/yum.repos.d'
				check_rhel_version
				backup_local_repo_file
				modify_rhel_mirror
				yum clean all
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

main
set_yum_proxy
