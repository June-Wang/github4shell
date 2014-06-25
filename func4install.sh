#functions for install

check_platform (){
local platform_info=`uname -m`
local platform=''
echo ${platform_info}|grep '64' >/dev/null 2>&1 && platform='x64' || platform='x86'
echo "${platform}"
}

check_system (){
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
                YUM_SOURCE_NAME='centos5-lan'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                YUM_SOURCE_NAME='RHEL5-lan'
                ;;
        'Red Hat Enterprise Linux Server release 6'*)
                SYSTEM='rhel6'
                YUM_SOURCE_NAME='RHEL6-lan'
                ;;
        'Debian GNU/Linux 6'*)
                SYSTEM='debian6'
                ;;
        'Debian GNU/Linux 7'*)
                SYSTEM='debian7'
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

set_install_cmd () {
local install_type="$1"
CONFIG_CMD='chkconfig'
case "${SYSTEM}" in
    centos5|rhel5|rhel6)
        local install_cmd='yum --skip-broken --nogpgcheck'
        local package="${YUM_PACKAGE}"
		local logfile='yum.log'
		ISSUE='redhat'
    ;;
    debian6|debian7)
        local install_cmd='apt-get --force-yes'
        local package="${APT_PACKAGE}"
        eval "${install_cmd} install -y chkconfig >/dev/null 2>&1" || eval "echo ${install_cmd} fail! 1>&2;exit 1"
		local logfile='apt.log'
		ISSUE='debian'
    ;;
    *)
        echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac

if [ "${ISSUE}" = 'redhat' -a "${install_type}" = 'lan' ];then
        install_cmd="yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${YUM_SOURCE_NAME}"
fi

local log_file="${TEMP_PATH}/${logfile}"

echo -n "Install ${package} please wait ...... "
if [ -n "${package}" ];then
		eval "${install_cmd} install -y ${package} >${log_file} 2>&1" || local install_stat='fail'
fi

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

create_user () {
local user="$1"
local shell="$2"
case "${shell}" in
    bash)
        local user_shell='/bin/bash'
    ;;
        nologin)
        local user_shell='/sbin/nologin -M'
        ;;
        ksh)
        local user_shell='/bin/ksh'
        ;;
    *)
        echo "This script not support ${shell}" 1>&2
                exit 1
        ;;
esac

id "${user}" >/dev/null 2>&1 ||\
/usr/sbin/useradd "${user}" -s ${user_shell}
}

echo_bye () {
        echo "Install ${PACKAGE} complete!"
}

exit_and_clear () {
                del_tmp
                echo_bye
}

set_auto_run () {
local project="$1"
	eval "${CONFIG_CMD} --add ${project};${CONFIG_CMD} ${project} on"
}
