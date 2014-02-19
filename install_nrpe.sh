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
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

set_install_cmd () {
local para="$1"
case "${SYSTEM}" in
    centos5|rhel5)
        local install_cmd='yum --skip-broken --nogpgcheck'
        local package="${YUM_PACKAGE}"
    ;;
    debian6|debian7)
        local install_cmd='apt-get --force-yes'
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

local log_file="${TEMP_PATH}/YUM.log"

echo -n "Install ${package} please wait ...... "
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

        echo -n "Download ${url} ...... "
        wget -q "${url}"  && echo 'done.' || local download='fail'
        if [ "${download}" = "fail" ];then
                echo "fail!" 1>&2 && del_tmp
                exit 1
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
        test -f "${cmd_log}" && rm -f ${cmd_log}
        for cmd in "$@"
        do
                ${cmd} >> "${cmd_log}" 2>&1 || compile='fail'
                if [ "${compile}" = 'fail' ]; then
                        echo "run ${cmd} error! please type: less ${cmd_log}" 1>&2 && del_tmp
                        exit 1
                fi
        done
        echo "done."
#               cd ..
}

download_and_check () {
        download_file "${PACKAGE_URL}/${PACKAGE}"
        check_file "${PACKAGE}"
}

config_xinetd () {
#if [ -f /etc/xinetd.d/nrpe ]; then
#        sed -i "s/only_from.*$/only_from = ${NAGIOS_SERVER}/g" /etc/xinetd.d/nrpe
#fi

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

echo_bye () {
        echo "Install ${PACKAGE} complete!"
}

exit_and_clear () {
                del_tmp
                echo_bye
}

main () {
#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET PACKAGE
YUM_SERVER='yum.suixingpay.com'
YUM_PACKAGE='gcc glibc glibc-common openssl-devel xinetd'
APT_PACKAGE='xinetd libssl-dev openssl build-essential'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

#CHECK SYSTEM AND CREATE TEMP DIR
check_system

#CHECK platform
check_platform

if [ "${platform}" = 'x64' -a "${SYATEM}" = 'debian7' ];then
	NRPE_PARA='--with-ssl-lib=/usr/lib/x86_64-linux-gnu'
else
	NRPE_PARA='--with-ssl-lib=/usr/lib/i386-linux-gnu'
fi

#create_tmp_dir
set_install_cmd 'lan'

#backup nrpe config
backup_nrpe_config

#check nagios account
id nagios >/dev/null 2>&1 ||\
/usr/sbin/useradd nagios -s /sbin/nologin -M -c "nagios user"

#Install nrpe-2.15
PACKAGE='nrpe-2.15.tar.gz'
create_tmp_dir
download_and_check
run_cmds "./configure ${NRPE_PARA}" 'make all' 'make install-plugin' 'make install-daemon' 'make install-daemon-config' 'make install-xinetd'
#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
