#!/bin/bash

#SET ENV
YUM_SERVER='yum.lefu.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='xinetd'
APT_PACKAGE='xinetd'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#PACKAGE='check-mk-agent_1.2.4p5-2_all.deb'
create_tmp_dir
case "${ISSUE}" in
	debian)
        	package='check-mk-agent_1.2.4p5-2_all.deb'
		install_cmd='dpkg -i'
	;;
	redhat)
		package='check_mk-agent-1.2.4p5-1.noarch.rpm'
		install_cmd='rpm -i'
	;;
    	*)
        echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac

temp_file="/tmp/${package}"
run_cmds "wget ${PACKAGE_URL}/${package} -O ${temp_file}" "eval ${install_cmd} ${temp_file}" "rm -f ${temp_file}"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
