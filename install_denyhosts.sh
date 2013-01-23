#!/bin/bash

check_system (){
system_info=`head -n 1 /etc/issue`
case "${system_info}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
                YUM_SOURCE_NAME='centos5-lan'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                YUM_SOURCE_NAME='RHEL5-lan'
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${system_info}" 1>&2
                exit 1
                ;;
esac
}

alias_yum () {
local yum_para="$1"

check_system
if [ "${yum_para}" = 'lan' ];then
        YUM="yum --disablerepo=\* --enablerepo=${yum_source_name}"
else
        YUM='yum'
fi
}

create_user () {
        username="$1"
        grep "${username}" /etc/passwd >/dev/null 2>&1 || useradd  -c "${username} user" -s /sbin/nologin ${username}
}

install_lib () {
local log_file="${TEMP_PATH}/yum_for_${MY_PROJECT}.log"

echo -n "install gcc gcc-c++ make please wait ...... "
eval "${YUM} install -y gcc gcc-c++ make >${log_file} 2>&1" || local yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo -e "yum not available!\nview error please type: less ${log_file}" 1>&2
        exit 1
fi
echo "done."
}

make_tmp_dir () {
mkdir -p "${INSTALL_PATH}" && cd "${INSTALL_PATH}" || local mkdir_dir='fail'
if [ "${mkdir_dir}" = "fail"  ];then
        echo "mkdir ${INSTALL_PATH} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
test -d "${INSTALL_PATH}" && rm -rf "${INSTALL_PATH}"
}

download_file () {
local   url="$1"
local   file=`echo ${url}|awk -F'/' '{print $NF}'`

if [ ! -f "${file}" ]; then
        echo -n "download ${url} ...... "
        wget -q "${url}"  && echo 'done.' || local download='fail'
        if [ "${download}" = "fail" ];then
                echo "download ${url} fail!" 1>&2 && del_tmp
                exit 1
        fi
fi
}

check_file () {
local file="$1"
local ex_dir=`echo "${file}"|awk -F'.tar|.tgz' '{print $1}'`
local dir="${INSTALL_PATH}/${ex_dir}"

test -f ${file} && tar xzf ${file} || eval "echo ${file} not exsit!;del_tmp;exit 1"
test -d ${dir} && cd ${dir} || eval "echo ${dir} not exsit!;del_tmp;exit 1"
echo -n "Compile ${file} please wait ...... "
}

run_cmds () {
local   cmd_log="${TEMP_PATH}/install_${PACKAGE}.log"
        test -f "${cmd_log}" && cat /dev/null > "${TEMP_PATH}/install_${dir}.log"
        for cmd in "$@"
        do
                ${cmd} >> "${cmd_log}" 2>&1 || compile='fail'
                if [ "${compile}" = 'fail' ]; then
                        echo "run ${cmd} error! please type: less ${cmd_log}" 1>&2 && del_tmp
                        exit 1
                fi
        done
        echo "done."
}

install_denyhosts () {
        download_file "${PACKAGE_URL}"
        check_file "${PACKAGE}"
        run_cmds 'python setup.py install'
        denyhosts_init='/usr/share/denyhosts/daemon-control-dist'
        start_file='/etc/init.d/denyhosts'
        test -e ${start_file} && rm -f ${start_file}
        test -e ${denyhosts_init} && ln -s ${denyhosts_init} ${start_file}
        denyhosts_cmd='/usr/bin/denyhosts.py'
        test -e ${denyhosts_cmd} || ln -s /usr/local/bin/denyhosts.py ${denyhosts_cmd}
        test -d /var/lock/subsys/ || mkdir -p /var/lock/subsys/
        cd ..
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
DAEMON_SLEEP = 30s
DAEMON_PURGE = 1h' > ${denyhosts_config}
        /etc/init.d/denyhosts restart
}

set_auto_run () {
        chkconfig --add ${MY_PROJECT}
        chkconfig ${MY_PROJECT} on
}

echo_bye () {
        echo "Install ${PACKAGE} complete!" && exit 0
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
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"
PACKAGE_URL="http://${YUM_SERVER}/tools/${PACKAGE}"
make_tmp_dir
install_${MY_PROJECT}
config_${MY_PROJECT}
set_auto_run
del_tmp
add_nagios
echo_bye
}

#SET TEMP PATH
TEMP_PATH='/usr/local/src'
INSTALL_DIR="install_$$"

#SET GLOBAL VAR
MY_PROJECT='denyhosts'
PACKAGE='DenyHosts-2.6.tar.gz'
YUM_SERVER='yum.suixingpay.com'

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT
main
