#!/bin/bash

epel_mirrors='epel.mirrors.local'
alt_mirrors='alt.mirrors.local'
debian_mirrors='debian.mirrors.local'

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

mirrors_for_epel () {
repo_file="${SOURCE_DIR}/epel.mirrors.repo"
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
baseurl=http://cache.mirrors.local/epel/\$releasever/SRPMS
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
baseurl=http://epel.mirrors.cache/epel/testing/\$releasever/SRPMS
failovermethod=priority
enabled=0
gpgkey=http://${epel_mirrors}/RPM-GPG-KEY-EPEL
gpgcheck=1" > ${repo_file}
}

mirrors_for_alt () {
repo_file="${SOURCE_DIR}/alt.mirrors.repo"
echo"[CentALT]
name=CentALT Packages for Enterprise Linux \$releasever - \$basearch
baseurl=http://alt.mirrors.local/\$releasever/\$basearch/
enabled=1
gpgcheck=0
" > ${repo_file}
}

main () {
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
'CentOS'*)
	SYSTEM='centos'
	SOURCE_DIR='/etc/yum.repos.d'
	backup_local_repo_file
	mirrors_for_epel
	mirrors_for_alt
	yum clean all
	;;
'Red Hat Enterprise Linux Server release'*)
	SYSTEM='rhel'
	SOURCE_DIR='/etc/yum.repos.d'
	backup_local_repo_file
	mirrors_for_epel
	mirrors_for_alt
	yum clean all
	;;
*)
	SYSTEM='unknown'
	echo "This script not support ${SYSTEM_INFO}"1>&2
	exit 1
	;;
esac
}

main
