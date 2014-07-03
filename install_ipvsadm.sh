#!/bin/bash

init_var () {
#set yum server
yum_server="$1"
file_name="$2"
yum_para="$3"
if [ "${yum_para}" = 'lan' ];then
	YUM='yum --disablerepo=\* --enablerepo=centos5-lan'
else
	YUM='yum'
fi
package_url="http://${yum_server}/tools/${file_name}"
}

#install gcc openssl xinetd
install_lib () {
log_name="$1"
echo "install gcc openssl make kernel-devel please wait ......"
eval "${YUM} install -y wget gcc gcc-c++ make openssl-devel kernel-devel > ${local_path}/yum_for_${log_name}.log 2>&1" || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!" 1>&2
        exit 1
fi
}

make_dir () {
mkdir -p "${local_path}/${install_dir}" && cd "${local_path}/${install_dir}" || mkdir_dir='fail'
if [ "${mkdir_dir}" = "fail"  ];then
        echo "mkdir ${install_dir} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
#del tmp file
test -d "${local_path}/${install_dir}" && rm -rf "${local_path}/${install_dir}"
}

#check
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

check_kernel_dir () {
	kernel_dir=`find /usr/src/kernels/ -maxdepth 1 -type d|grep -E '/2.6.*[86|64]$'|head -n 1`
	if [ -z "${kernel_dir}" ];then
		echo "kernel dir not find! please type: yum -y install kernel-devel" 1>&2
		del_tmp
		exit 1
	fi	
}

create_soft_link () {
	check_kernel_dir
	test -L /usr/src/linux || ln -s ${kernel_dir}/ /usr/src/linux
}

install_ipvsadm () {
	install_pre "${package_url}"
	check_kernel_dir
        create_soft_link
	run_cmds 'make' 'make install'
	cd ..
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete!" && exit 0
}

main () {
my_project='ipvsadm'
init_var 'yum.suixingpay.com' 'ipvsadm-1.24.tar.gz' 'lan'
install_lib "${my_project}"
make_dir
check_urls "${package_url}"
install_ipvsadm
del_tmp
echo_bye "${my_project}"
}

local_path='/usr/local/src'
install_dir="install_$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${install_dir}"  EXIT
main
