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
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

turn_off_syslog(){
local nrpe_config='/etc/xinetd.d/nrpe'

if [ -f "${nrpe_config}" ];then
        sed -r -i 's/log_on_failure.*$/log_type = file \/dev\/null/' ${nrpe_config}
fi
}

config_xinetd () {
if [ -f /etc/services ];then
        grep '5666' /etc/services >/dev/null 2>&1 || echo "nrpe 5666/tcp #NRPE" >> /etc/services
        /etc/init.d/xinetd restart
        sleep 1
        ${CONFIG_CMD} xinetd on
fi
}

backup_nrpe_config () {
local nrpe_config='/usr/local/nagios/etc/nrpe.cfg'
if [ -f "${nrpe_config}" ];then
                mv ${nrpe_config} ${nrpe_config}.bak`date -d now +"%F_%H-%M-%S"`
fi
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
set_install_cmd 'lan'

platform=`check_platform`

#FOR debian7
[ "${platform}" = 'x64' -a "${SYATEM}" = 'debian7' ] &&\
NRPE_PARA='--with-ssl-lib=/usr/lib/x86_64-linux-gnu' ||\
NRPE_PARA='--with-ssl-lib=/usr/lib/i386-linux-gnu'

[ "${SYATEM}" != 'debian7' ] && NRPE_PARA=''

#Backup NRPE config
backup_nrpe_config

#Created user
create_user "nagios" "bash"

#Install nrpe-2.15.tar.gz
PACKAGE='nrpe-2.15.tar.gz'
create_tmp_dir
download_and_check
run_cmds "./configure ${NRPE_PARA}" 'make all' 'make install-plugin' 'make install-daemon' 'make install-daemon-config' 'make install-xinetd'

#CONFIG NRPE
turn_off_syslog
config_xinetd

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
