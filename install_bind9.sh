#!/bin/bash

init_var () {
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

install_lib () {
log_name="$1"
log_file="${local_path}/yum_for_${log_name}.log"
echo -n "install gcc gcc-c++ make openssl openssl-devel please wait ...... "
eval "${YUM} install -y gcc gcc-c++ make openssl openssl-devel >${log_file} 2>&1" || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo -e "yum not available!\nview error please type: less ${log_file}" 1>&2
        exit 1
fi
echo "done."
}

make_tmp_dir () {
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
                echo -n "download ${url} ...... "
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

install_bind9 () {
	install_pre "${package_url}"
	run_cmds './configure  --enable-threads --disable-openssl-version-check' 'make' 'make install'
	test -e /etc/rndc.conf || /usr/local/sbin/rndc-confgen |\
	awk '/^# Start of rndc.conf/,/^# End of rndc.conf/'|sed '1d;$d' > /etc/rndc.conf
	test -e /etc/named.conf || /usr/local/sbin/rndc-confgen |\
	awk '/^# Use with the following in named.conf/,/^# End of named.conf/'|sed '1d;$d;s/^# //'> /etc/named.conf
	test -d /var/named || mkdir -p /var/named
	
	cd ..
}

set_auto_run () {
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete! Please type : /etc/init.d/${program} start " && exit 0
}

main () {
my_project='BIND9'
init_var 'yum.suixingpay.com' 'bind-9.9.1-P1.tar.gz' 'lan'
install_lib "${my_project}"
make_tmp_dir
check_urls "${package_url}"
install_pcre
set_auto_run "${my_project}"
del_tmp
echo_bye "${my_project}"
}

#local install path
local_path='/usr/local/src'
install_dir="install_$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${install_dir}"  EXIT
main
