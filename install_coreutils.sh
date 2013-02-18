#!/bin/bash

#SET TEMP PATH
TEMP_PATH='/usr/local/src'
INSTALL_DIR="install_$$"

#SET GLOBAL VAR
MY_PROJECT='coreutils'
PACKAGE='coreutils-8.21.tar.gz'
YUM_SERVER='yum.suixingpay.com'
#YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++ zlib zlib-devel bzip2-libs bzip2-devel pkgconfig fuse fuse-devel'
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++'
APT_PACKAGE='build-essential'

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
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

install_package () {
local para="$1"
case "${SYSTEM}" in
    centos5|rhel5)
        local install_cmd='yum --skip-broken --nogpgcheck'
        local package="${YUM_PACKAGE}"
    ;;
    debian6)
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

check_system
#create_user
create_tmp_dir
#set_yum 'lan'
install_package 'lan'
install_coreutils
#set_auto_run
del_tmp
echo_bye
}

main
