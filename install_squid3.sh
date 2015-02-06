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
APT_PACKAGE='build-essential gawk'

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
set_install_cmd 'net'

#Created user
create_user "squid" "nologin"

#Install 
PACKAGE='squid-3.5.1.tar.gz'
create_tmp_dir
download_and_check
run_cmds './configure --prefix=/usr/local/squid' 'make all' 'make install'

#init
/usr/local/squid/sbin/squid -zX
mkdir -p /usr/local/squid/var/logs /usr/local/squid/var/cache 
chown -R squid:squid /usr/local/squid/var/logs /usr/local/squid/var/cache

squid_conf='/usr/local/squid/etc/squid.conf'
grep 'cache_effective_' ${squid_conf} >/dev/null 2>&1 ||\
echo 'cache_effective_user squid
cache_effective_group squid' >> ${squid_conf}
/usr/local/squid/sbin/squid -s

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
