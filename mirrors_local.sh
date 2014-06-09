#!/bin/bash

epel_mirrors='epel.mirrors.local'
debian_mirrors='debian.mirrors.local'
#debian_mirrors='ftp.jp.debian.org/debian/'
atom_mirrors='atom.mirrors.local'

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

mirrors_for_alt () {
local repo_file="${SOURCE_DIR}/alt.mirrors.repo"
echo "[CentALT]
name=CentALT Packages for Enterprise Linux \$releasever - \$basearch
baseurl=http://alt.mirrors.local/\$releasever/\$basearch/
enabled=1
gpgcheck=0" > ${repo_file}
}

mirrors_for_atom () {
local repo_file="${SOURCE_DIR}/atom.mirrors.repo"
echo "[atomic]
name = CentOS / Red Hat Enterprise Linux \$releasever - atomicrocketturtle.com
mirrorlist = http://${atom_mirrors}/mirrorlist/atomic/centos-\$releasever-\$basearch
enabled = 1
priority = 1
protect = 0
#gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY.art.txt
#    file:///etc/pki/rpm-gpg/RPM-GPG-KEY.atomicorp.txt
#gpgcheck = 0

# Almost Stable, release candidates for [atomic]
[atomic-testing]
name = CentOS / Red Hat Enterprise Linux \$releasever - atomicrocketturtle.com - (Testing)
mirrorlist = http://${atom_mirrors}/mirrorlist/atomic-testing/centos-\$releasever-\$basearch
enabled = 0
priority = 1
protect = 0
#gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY.art.txt
#    file:///etc/pki/rpm-gpg/RPM-GPG-KEY.atomicorp.txt
#gpgcheck = 1
gpgcheck = 0" > ${repo_file}
}

backup_source_list () {
source_file="${SOURCE_DIR}/sources.list"
if [ -e ${source_file} ];then
	local my_date=`date -d "now" +"%F"`
	mv "${source_file}" "${source_file}.${my_date}.$$"
else
	echo "Can not find ${source_file},please check!" 1>&2
#        exit 1
fi
}

mirrors_for_debian () {
debian_release=`echo "${SYSTEM_INFO}" |\
grep -oP 'Debian GNU/Linux\s+\d+'|awk '{print $NF}'`
case "${debian_release}" in
	7)
		DEBIAN_VERSION='wheezy'
		DEBIAN_ISSUE='7'
		backup_source_list
		echo "deb http://${debian_mirrors}/${DEBIAN_ISSUE}/x64/dvd1/ stable contrib main
deb http://${debian_mirrors}/${DEBIAN_ISSUE}/x64/dvd2/ stable contrib main
deb http://${debian_mirrors}/${DEBIAN_ISSUE}/x64/dvd3/ stable contrib main" > ${source_file}
	;;
	6)
		DEBIAN_VERSION='squeeze'
		DEBIAN_ISSUE='6'
		backup_source_list
		echo "deb http://${debian_mirrors}/${DEBIAN_ISSUE}/x64/dvd1/debian/ ${DEBIAN_VERSION} contrib main" > ${source_file}
#						echo "deb http://${debian_mirrors} ${DEBIAN_VERSION} main
#deb-src http://${debian_mirrors} ${DEBIAN_VERSION} main
#deb http://${debian_mirrors} ${DEBIAN_VERSION}-updates main contrib
#deb-src http://${debian_mirrors} ${DEBIAN_VERSION}-updates main contrib" > ${source_file}
	;;
	*)
		echo "This script not support ${SYSTEM_INFO}" 1>&2
		exit 1
	;;
esac

local apt_conf_d='/etc/apt/apt.conf.d'
local apt_conf="${apt_conf_d}/00trustlocal"
test -d ${apt_conf_d} || mkdir -p ${apt_conf_d}
echo 'Aptitude::Cmdline::ignore-trust-violations "true";' > ${apt_conf}
aptitude update
}

set_for_redhat () {
backup_local_repo_file
mirrors_for_epel
#mirrors_for_atom
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
#	check_debian_version
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
