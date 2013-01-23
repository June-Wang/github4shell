#!/bin/bash

#set yum server
yum_server='yum.suixingpay.com'

#alias yum local
alias yum='yum --disablerepo=\* --enablerepo=centos5-lan'

#download url
inotify_url="http://${yum_server}/tools/inotify-tools-3.14.tar.gz"

#local install path
local_path='/usr/local/src'

install_dir="install_$$"

#install gcc openssl
install_lib () {
log_name="$1"
echo -n "install gcc openssl glib2 please wait ......"
yum -y install gcc gcc-c++ openssl openssl-devel glib2-devel > ${local_path}/yum_for_${log_name}.log 2>&1 && echo 'done.' || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!" 1>&2
        exit 1
fi
}

#mkdir for install
make_dir () {
test -d "${local_path}" || mkdir -p "${local_path}"
cd ${local_path}
mkdir -p ${install_dir} && cd ${install_dir} || mkdir_dir='fail'

if [ "${mkdir_dir}" = 'fail'  ];then
        echo "mkdir ${install_dir} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
#del tmp file
test -d "${local_path}/${install_dir}" && rm -rf "${local_path}/${install_dir}"
}

check_urls () {
for url in "$@"
do
        file=`echo ${url}|awk -F'/' '{print $NF}'`
        if [ ! -f "${file}" ]; then
                echo -n "download ${url} ..."
                wget -q "${url}"  && echo 'done.' || download='fail'
                if [ "${download}" = "fail" ];then
                        echo "download ${url} fail!" 1>&2 && del_tmp
                        exit 1
                fi
        fi
done
}

install_pre () {
        install_url="$1"
        file=`echo ${install_url}|awk -F'/' '{print $NF}'`
        dir=`echo ${file}|awk -F'.tar' '{print $1}'`
        test -e "${file}" && tar xzf ${file} || tar_file='not_exist'
        cd ${dir} || file_dir='not_exist'
        if [ "${tar_file}" = 'not_exist' ];then
                echo "${file} not exist!" 1>&2 && del_tmp
                exit 1
        fi
        if [ "${file_dir}" = 'not_exist' ];then
                echo "plesse check ${file}!" 1>&2 && del_tmp
                exit 1
        fi
        echo -n "Compile ${dir} please wait ...... "
}

run_cmds () {
        cmd_log="${local_path}/install_${dir}.log"
        test -f "${cmd_log}" && cat /dev/null > "${local_path}/install_${dir}.log"
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

install_inotify () {
	install_pre "${inotify_url}"
	run_cmds './configure' 'make' 'make install'
	cd ..
}

main (){
install_lib 'inotify'
make_dir
check_urls "${inotify_url}"
install_inotify
del_tmp
}

main
echo "Install inotify complete!" && exit 0
