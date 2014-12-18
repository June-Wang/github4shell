#!/bin/bash

init_var () {
#set yum server
yum_server="$1"
file_name="$2"
yum_para="$3"
if [ "${yum_para}" = 'lan' ];then
	YUM='yum --disablerepo=\* --enablerepo=centos5-lan'
else
	YUM='yum --skip-broken --nogpgcheck'
fi
keepalived_url="http://${yum_server}/tools/${file_name}"
}

#install gcc openssl xinetd
install_lib () {
log_name="$1"
echo -n "install gcc openssl make kernel-devel please wait ......"
eval "${YUM} install -y wget gcc gcc-c++ make openssl-devel kernel-devel > ${local_path}/yum_for_${log_name}.log 2>&1" || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!" 1>&2
        exit 1
fi
echo "done."
}

make_dir () {
mkdir -p "${local_path}/${install_dir}" && cd "${local_path}/${install_dir}" || mkdir_dir='fail'
if [ "${mkdir_dir}" = "fail"  ];then
        echo "mkdir ${install_dir} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
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

check_kernel_dir () {
	kernel_dir=`find /usr/src/kernels/ -maxdepth 1 -type d|grep -E '/2.6.*[86|64]$'`
	if [ -z "${kernel_dir}" ];then
		echo "kernel dir not find! please type: yum -y install kernel-devel" 1>&2
		del_tmp
		exit 1
	fi	
}

modify_source_code () {
	source_file="${local_path}/${install_dir}/${dir}/keepalived/libipvs-2.6/ip_vs.h"
	if [ -f "${source_file}" ];then	
		sed -r -i 's/^#include <asm\/types.h>.*$/&\n#include <sys\/types.h>/;/^#include <sys\/types.h>/d' "${source_file}"
	else
		echo "${${source_file}} not find!" 1>&2
		exit 1
	fi
}

install_keepalived () {
	install_pre "${keepalived_url}"
	if [ "${receive_para}" = 'lvs' ];then
		modify_source_code
		check_kernel_dir
        	run_cmds "./configure --with-kernel-dir=${kernel_dir}" 'make' 'make install'
	else
		run_cmds "./configure" 'make' 'make install'
	fi
	cp /usr/local/sbin/keepalived /usr/sbin/
	test -e /etc/sysconfig/keepalived || cp keepalived/etc/init.d/keepalived.sysconfig /etc/sysconfig/keepalived
	test -e /etc/rc.d/init.d/keepalived || cp keepalived/etc/init.d/keepalived.init /etc/rc.d/init.d/keepalived
	chmod +x /etc/rc.d/init.d/keepalived
	test -d /etc/keepalived || mkdir -p /etc/keepalived
	test -e /etc/keepalived/keepalived.conf|| cp keepalived/etc/keepalived/keepalived.conf /etc/keepalived/
	cd ..
}

set_auto_run () {
auto_service="$1"
chkconfig --add "${auto_service}"
chkconfig "${auto_service}" on
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete! Please type : /etc/init.d/keepalived start " && exit 0
}

main () {
my_project='keepalived'
init_var 'yum.suixingpay.com' 'keepalived-1.2.2.tar.gz' 'lan'
install_lib "${my_project}"
make_dir
check_urls "${keepalived_url}"
install_keepalived
set_auto_run "${my_project}"
del_tmp
echo_bye "${my_project}"
}

#local install path
local_path='/usr/local/src'
install_dir="install_$$"
receive_para="lvs"

main
