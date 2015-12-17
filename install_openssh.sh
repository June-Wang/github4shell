#!/bin/bash

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
#        'Debian GNU/Linux 6'*)
#                SYSTEM='debian6'
#                CONFIG_CMD='sysv-rc-conf'
#                ;;
#        'Debian GNU/Linux 7'*)
#                SYSTEM='debian7'
#                CONFIG_CMD='sysv-rc-conf'
#                ;;
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
#    debian6|debian7)
#        local install_cmd='apt-get --force-yes'
#        local package="${APT_PACKAGE}"
#        eval "${install_cmd} install -y sysv-rc-conf >/dev/null 2>&1" || eval "echo ${install_cmd} fail! 1>&2;exit 1"
#    ;;
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
YUM_SERVER='yum.server.local'
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++ pam-devel'
APT_PACKAGE='build-essential'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'net'

#Stop sshd service and clear old version
SSH_SERVICE="/etc/init.d/sshd"
test -f ${SSH_SERVICE} && ${SSH_SERVICE} stop
#rpm -qa openssh*|xargs -r -i rpm -e "{}"

#Install zlib-1.2.8
PACKAGE='zlib-1.2.8.tar.gz'
create_tmp_dir
download_and_check
run_cmds './configure' 'make' 'make install'
#EXIT AND CLEAR TEMP DIR
exit_and_clear

#Install openssl-0.9.8y
PACKAGE='openssl-0.9.8zg.tar.gz'
create_tmp_dir
download_and_check
run_cmds './config --prefix=/usr/ shared' 'make' 'make install'
#EXIT AND CLEAR TEMP DIR
exit_and_clear

#install
PACKAGE='openssh-6.9p1.tar.gz'
create_tmp_dir
download_and_check
run_cmds './configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-md5-passwords' 'make' 'make install' 'cp contrib/redhat/sshd.init /etc/init.d/sshd' 'cp contrib/redhat/sshd.pam /etc/pam.d/sshd'
#EXIT AND CLEAR TEMP DIR
exit_and_clear

#Modify sshd_config
SSH_CONFIG="/etc/ssh/sshd_config"
test -f ${SSH_CONFIG} && sed -r -i 's/^(GSSAPI*)/#\1/g;s/^(UsePAM*)/#\1/g;s/^(UseDNS*)/#\1/g' ${SSH_CONFIG} ||\
eval "echo ${SSH_CONFIG} not found!;exit 1"
grep -E '^#-=SET SSHD=-' ${SSH_CONFIG} ||\
echo "#-=SET SSHD=-
UseDNS no   
UsePAM yes

PasswordAuthentication yes
PermitRootLogin yes 
PermitEmptyPasswords no
PasswordAuthentication yes
" >> ${SSH_CONFIG}

#Add PAM model for sshd
#SSHD4PAM_CONFIG='/etc/pam.d/sshd'
#test -f ${SSHD4PAM_CONFIG} ||\ 
#echo '#%PAM-1.0
#auth       include      system-auth
#account    required     pam_nologin.so
#account    include      system-auth
#password   include      system-auth
#session    optional     pam_keyinit.so force revoke
#session    include      system-auth
#session    required     pam_loginuid.so
#' > ${SSHD4PAM_CONFIG}

SSH_CONFIG="/etc/ssh/ssh_config"
test -f ${SSH_CONFIG} && sed -i 's/GSSAPIAuthentication/#GSSAPIAuthentication/;s/^Host/#Host/' ${SSH_CONFIG} ||\
eval "echo ${SSH_CONFIG} not found!;exit 1"

#Restart sshd service
test -f ${SSH_SERVICE} && ${SSH_SERVICE} start
${CONFIG_CMD} sshd on

}

main
