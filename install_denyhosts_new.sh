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

config_denyhosts () {
        local        denyhosts_config='/usr/share/denyhosts/denyhosts.cfg'
        test -e ${denyhosts_config} && mv ${denyhosts_config} ${denyhosts_config}.`date -d now +"%F"`.$$
        echo 'SECURE_LOG = /var/log/secure
HOSTS_DENY = /etc/hosts.deny
PURGE_DENY = 1h 
BLOCK_SERVICE  = sshd
DENY_THRESHOLD_INVALID = 5
DENY_THRESHOLD_VALID = 5
DENY_THRESHOLD_ROOT = 5
DENY_THRESHOLD_RESTRICTED = 1
WORK_DIR = /usr/share/denyhosts/data
SUSPICIOUS_LOGIN_REPORT_ALLOWED_HOSTS=YES
HOSTNAME_LOOKUP=NO
LOCK_FILE = /var/lock/subsys/denyhosts
ADMIN_EMAIL = 
SMTP_HOST = localhost
SMTP_PORT = 25
SMTP_FROM = DenyHosts <nobody@localhost>
SMTP_SUBJECT = DenyHosts Report
SYSLOG_REPORT=YES
AGE_RESET_VALID=5d
AGE_RESET_ROOT=25d
AGE_RESET_RESTRICTED=25d
AGE_RESET_INVALID=10d
DAEMON_LOG = /var/log/denyhosts
DAEMON_LOG_TIME_FORMAT = %F %T
local MY_PROJECT='denyhosts'
DAEMON_SLEEP = 30s
DAEMON_PURGE = 1h' > ${denyhosts_config}
        /etc/init.d/denyhosts restart
}

add_nagios () {
local nagios_plugin='check_denyhosts.sh'
local nagios_cfg='/usr/local/nagios/etc/nrpe.cfg'
local nagios_lib='/usr/local/nagios/libexec'

if [ -e ${nagios_cfg} ];then
        test -d ${nagios_lib} && cd ${nagios_lib} || eval "echo ${nagios_lib} not exsit!;exit 1"
        wget -q "http://${YUM_SERVER}/shell/${nagios_plugin}" || eval "echo download http://${YUM_SERVER}/shell/${nagios_plugin} fail!;exit 1"
        test -e "${nagios_lib}/${nagios_plugin}" && chmod +x "${nagios_lib}/${nagios_plugin}"
        grep "check_${MY_PROJECT}" ${nagios_cfg} >/dev/null 2>&1 || local nagios='notset'
        if [ "${nagios}" = 'notset' ];then
                echo "command[check_${MY_PROJECT}]=${nagios_lib}/${nagios_plugin}" >> ${nagios_cfg}
        fi
fi
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#Install DenyHosts-2.6
PACKAGE='DenyHosts-2.6.tar.gz'
create_tmp_dir
download_and_check
run_cmds 'python setup.py install'
denyhosts_init='/usr/share/denyhosts/daemon-control-dist'
init_file='/etc/init.d/denyhosts'
test -e ${init_file} && rm -f ${init_file}
test -e ${denyhosts_init} && ln -s ${denyhosts_init} ${init_file}
denyhosts_cmd='/usr/bin/denyhosts.py'
test -e ${denyhosts_cmd} || ln -s /usr/local/bin/denyhosts.py ${denyhosts_cmd}
test -d /var/lock/subsys/ || mkdir -p /var/lock/subsys/
#Setting
config_denyhosts
#Add2nagios
add_nagios
#set auto run
MY_PROJECT='denyhosts'
set_auto_run "${MY_PROJECT}"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}
