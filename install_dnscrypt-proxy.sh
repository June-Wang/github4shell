#!/bin/bash

#SET ENV
YUM_SERVER='yum.suixingpay.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++'
APT_PACKAGE='build-essential'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="${PACKAGE_URL}/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#Install libsodium-0.4.5.tar.gz
PACKAGE='libsodium-0.4.5.tar.gz'
create_tmp_dir
download_and_check
run_cmds './configure' 'make' 'make check' 'make install'

#EXIT AND CLEAR TEMP DIR
#exit_and_clear

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd  "" 'lan'

#Install libsodium-0.4.5.tar.gz
PACKAGE='dnscrypt-proxy-1.3.3.tar.gz'
create_tmp_dir
download_and_check
run_cmds './configure --host=arm' 'make' 'make install'

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
