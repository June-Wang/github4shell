#!/bin/bash

#SET TEMP PATH
TEMP_PATH='/usr/local/src'
INSTALL_DIR="install_$$"

#SET GLOBAL VAR
MY_PROJECT='coreutils'
PACKAGE='coreutils-8.21.tar.gz'
YUM_SERVER='yum.suixingpay.com'
#YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++ zlib zlib-devel bzip2-libs bzip2-devel pkgconfig fuse fuse-devel'

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

set_yum () {
local yum_para="$1"
if [ "${yum_para}" = 'lan' ];then
        YUM="yum --disablerepo=\* --enablerepo=${YUM_SOURCE_NAME}"
else
        YUM='yum'
fi
}

create_user () {
        username="${MY_PROJECT}"
        grep "${username}" /etc/passwd >/dev/null 2>&1 || useradd  -c "${username} user" -s /sbin/nologin ${username}
}

install_yum_package () {
local yum_package="$1"
local log_file="${TEMP_PATH}/yum_for_${MY_PROJECT}.log"

echo -n "install ${yum_package} please wait ...... "
eval "${YUM} install -y ${yum_package} >${log_file} 2>&1" || local yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo -e "yum not available!\nview error please type: less ${log_file}" 1>&2
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

install_coreutils () {
        download_file "${PACKAGE_URL}"
        check_file "${PACKAGE}"
        run_cmds 'export FORCE_UNSAFE_CONFIGURE=1' './configure' 'make' 'make install'
        cd ..
}

echo_bye () {
        echo "Install ${PACKAGE} complete!" && exit 0
}

main () {
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"
PACKAGE_URL="http://${YUM_SERVER}/tools/${PACKAGE}"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

#check_system
#create_user
create_tmp_dir
#set_yum 'lan'
#install_yum_package "${YUM_PACKAGE}"
install_coreutils
#set_auto_run
del_tmp
echo_bye
}

main
