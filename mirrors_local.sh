#!/bin/bash

debian_mirrors='debian.mirrors.local'

#set DNS
echo 'nameserver 192.168.1.201' > /etc/resolv.conf

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
#        exit 1
fi
}

mirrors_for_debian () {
local source_file="${SOURCE_DIR}/sources.list"
debian_release=`echo "${SYSTEM_INFO}" |\
cat /etc/issue|head -n1|grep -oE '[0-9]+'|head -n1`
case "${debian_release}" in
        7)
                DEBIAN_VERSION='wheezy'
                DEBIAN_ISSUE='7'
                backup_source_list
                echo "deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd1/ stable contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd2/ stable contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd3/ stable contrib main" > ${source_file}
        ;;
        6)
                DEBIAN_VERSION='squeeze'
                DEBIAN_ISSUE='6'
                backup_source_list
                echo "deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd1/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd2/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd3/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd4/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd5/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd6/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd7/debian/ ${DEBIAN_VERSION} contrib main
deb http://${debian_mirrors}/debian/${DEBIAN_ISSUE}/x64/dvd8/debian/ ${DEBIAN_VERSION} contrib main" > ${source_file}
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

main () {
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
#'CentOS'*)
#        SYSTEM='centos'
#        SOURCE_DIR='/etc/yum.repos.d'
#        set_for_redhat
#        ;;
#'Red Hat Enterprise Linux Server release'*)
#        SYSTEM='rhel'
#        SOURCE_DIR='/etc/yum.repos.d'
#        set_for_redhat
#        ;;
'Debian'*)
        SYSTEM='debian'
        SOURCE_DIR='/etc/apt'
#       check_debian_version
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
