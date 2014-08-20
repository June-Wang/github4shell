#!/bin/bash

check_system (){
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
                INIT_SCRIPT='init_redhat.sh'
                SOURCE='yum_local.sh'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                INIT_SCRIPT='init_redhat.sh'
                SOURCE='yum_local.sh'
                ;;
        'Debian GNU/Linux 6'*)
                SYSTEM='debian6'
                INIT_SCRIPT='init_debian.sh'
                SOURCE='mirrors_local.sh'
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

#http server
http_server='192.168.16.22'
url="http://${http_server}/shell"

#print error
fail () {
        value=$1
        message=$2
        if [ "${value}" = "fail" ];then
                echo "$2" 1>&2
                exit 1
        fi
}

#check_system 

download_exec () {
local file="$1"
wget -q "${url}/${file}" || local case='fail'
fail "${case}" "${url}/${file} not exist!"
/bin/bash "${file}"
[ -f "${file}" ] && rm -f "${file}"
}

main () {
check_system

files=(
${SOURCE}
${INIT_SCRIPT}
install_nagios-plugins.sh
install_nrpe.sh
install_check_mk.sh
add_history.sh
install_snmp.sh
)

for file in "${files[@]}"
do
#       message=`echo "${file}"|sed 's/sh$/ /g;s/_/ /g'`
#       echo "${message} ..."
	download_exec "${file}"
done
}

main
