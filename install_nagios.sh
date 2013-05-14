#!/bin/bash

check_platform (){
platform_info=`uname -m`
echo ${platform_info}|grep '64' >/dev/null 2>&1 && platform='x64' || platform='x86'
}

check_system (){
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
                YUM_SOURCE_NAME='centos5-lan'
                CONFIG_CMD='chkconfig'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                YUM_SOURCE_NAME='RHEL5-lan'
                CONFIG_CMD='chkconfig'
                ;;
        'Debian GNU/Linux 6'*)
                SYSTEM='debian6'
                CONFIG_CMD='sysv-rc-conf'
                ;;
        'Debian GNU/Linux 7'*)
                SYSTEM='debian7'
                CONFIG_CMD='sysv-rc-conf'
				check_platform
				if [ "${platform}" = 'x64' ];then
					NRPE_PARA='--with-ssl-lib=/usr/lib/x86_64-linux-gnu'
				else
					NRPE_PARA='--with-ssl-lib=/usr/lib/i386-linux-gnu'
				fi
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

create_user () {
        username="$1"
        grep "${username}" /etc/passwd >/dev/null 2>&1 || useradd  -c "${username} user" -s /sbin/nologin ${username}
}

install_package () {
local para="$1"
case "${SYSTEM}" in
        centos5|rhel5)
                local install_cmd='yum --skip-broken --nogpgcheck'
                local package="${YUM_PACKAGE}"
        ;;
        debian6|debian7)
                local install_cmd='apt-get'
                local package="${APT_PACKAGE}"
                eval "${install_cmd} install -y sysv-rc-conf >/dev/null 2>&1" || eval "echo ${install_cmd} fail! 1>&2;exit 1"
        ;;
        *)
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac

if [ "${install_cmd}" = 'yum' -a "${para}" = 'lan' ];then
        install_cmd="yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${YUM_SOURCE_NAME}"
fi

local log_file="${TEMP_PATH}/${MY_PROJECT}.log"

echo -n "install ${package} please wait ...... "
eval "${install_cmd} install -y ${package} >${log_file} 2>&1" || local install_stat='fail'
if [ "${install_stat}" = "fail" ];then
        echo -e "${install_cmd} not available!\nview error please type: less ${log_file}" 1>&2
        exit 1
fi
echo "done."
}

create_tmp_dir () {
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
        test -f "${cmd_log}" && rm -f "${cmd_log}"
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

install_nagios_plugins () {
        download_file "${PACKAGE_URL}"
        check_file "${PACKAGE}"
        run_cmds './configure --with-nagios-user=nagios --with-nagios-group=nagios' 'make' 'make install'
        cd ..
}

install_nrpe () {
        download_file "${PACKAGE_URL}"
        check_file "${PACKAGE}"
        run_cmds "./configure ${NRPE_PARA}" 'make all' 'make install-plugin' 'make install-daemon' 'make install-daemon-config' 'make install-xinetd'
        cd ..
}

add_check_cpu_utilization () {
local nrpe_cfg='/usr/local/nagios/etc/nrpe.cfg'

if [ -f "${nrpe_cfg}" ];then
        grep 'check_root' ${nrpe_cfg} >/dev/null 2>&1 ||\
        echo 'command[check_root]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /' >> ${nrpe_cfg}
        grep 'check_cpu_utilization' ${nrpe_cfg} >/dev/null 2>&1 ||\
        echo 'command[check_cpu_utilization]=/usr/local/nagios/libexec/check_cpu_utilization.sh -w 100 -c 300' >> ${nrpe_cfg}
fi

if [ -d /usr/local/nagios/libexec ];then
        cd /usr/local/nagios/libexec
        wget -q http://${YUM_SERVER}/shell/check_cpu_utilization.sh && chmod +x check_cpu_utilization.sh ||\
        echo "download fail http://${YUM_SERVER}/shell/check_cpu_utilization.sh"
        test -d /var/log/cpu_utilization || mkdir -p /var/log/cpu_utilization
        chown -R nagios.nagios /var/log/cpu_utilization
fi
}

config_xinetd () {
if [ -f /etc/xinetd.d/nrpe ]; then
        sed -i "s/only_from.*$/only_from = ${NAGIOS_SERVER}/g" /etc/xinetd.d/nrpe
fi

if [ -f /etc/services ];then
        grep '5666' /etc/services >/dev/null 2>&1 || echo "nrpe 5666/tcp #NRPE" >> /etc/services
        /etc/init.d/xinetd restart
        sleep 1
        ${CONFIG_CMD} xinetd on
fi
}

echo_bye () {
        echo "Install ${PACKAGE} complete! " && exit 0
}

step1 () {
PACKAGE_URL="http://${YUM_SERVER}/tools/${PACKAGE}"
check_system
create_user 'nagios'
create_tmp_dir
install_package 'lan'
install_nagios_plugins
}

step2 () {
PACKAGE_URL="http://${YUM_SERVER}/tools/${PACKAGE}"
install_nrpe
config_xinetd
}

step3 () {
add_check_cpu_utilization
del_tmp
echo_bye
}

#SET TEMP PATH
TEMP_PATH='/usr/local/src'
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

#SET GLOBAL VAR
MY_PROJECT='nagios'
PACKAGE='nagios-plugins-1.4.16.tar.gz'
YUM_SERVER='yum.suixingpay.com'
YUM_PACKAGE='gcc glibc glibc-common openssl-devel xinetd'
APT_PACKAGE='xinetd libssl-dev openssl build-essential'
NAGIOS_SERVER='nagios.suixingpay.local'
step1
MY_PROJECT='nrpe'
PACKAGE='nrpe-2.13.tar.gz'
YUM_SERVER='192.168.29.248'
step2
step3
