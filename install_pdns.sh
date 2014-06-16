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

create_user () {
	username="$1"
	grep "${username}" /etc/passwd >/dev/null 2>&1 || useradd  -c "${username} user" -s /sbin/nologin ${username}
}

install_lib () {
log_name="$1"
yum_package="$2"
log_file="${local_path}/yum_for_${log_name}.log"
echo -n "install ${yum_package} please wait ...... "
eval "${YUM} install -y ${yum_package} >${log_file} 2>&1" || yum_install='fail'
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
        dir=`echo ${file}|awk -F'.tar|.tgz' '{print $1}'`
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

install_pdns () {
	install_pre "${package_url}"
	run_cmds './configure --enable-ipv6' 'make' 'make check' 'make install'
	cp ./src/rc/RedHat/pdnsd /etc/rc.d/init.d/
	cd /etc/rc.d/rc3.d
	ln -f -s ../init.d/pdnsd S78pdnsd
	ln -f -s ../init.d/pdnsd K78pdnsd
	chmod +x /etc/rc.d/init.d/pdnsd
	chmod +x /etc/init.d/pdnsd
	test -d /var/cache/pdnsd/ || mkdir -p /var/cache/pdnsd/
#	useradd -s /sbin/nologin pdnsd
	chown -R pdnsd.pdnsd /var/cache/pdnsd/
	cd ..
}

set_conf (){
	test -e /usr/local/etc/pdnsd.conf || echo 'server {
	label="dns-server";
	ip=127.0.0.1;
	port=5353;
	timeout=30;
	interval=30;
	uptest=query;
	ping_timeout=0;
	purge_cache=off;
}

global {
	perm_cache=10240;
	cache_dir="/var/cache/pdnsd";
	run_as="pdnsd";
	server_ip=eth0;
}'> /usr/local/etc/pdnsd.conf
} 

set_auto_run (){
	service_name="$1"
	chkconfig --add "${service_name}"
	chkconfig "${service_name}" on
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete!Please type: /etc/init.d/pdns start" && exit 0
}

main () {
my_project='pdns'
init_var 'yum.suixingpay.com' 'pdnsd-1.2.9a.tar.gz' 'lan'
install_lib "${my_project}" "gcc gcc-c++ glibc-devel make"
make_tmp_dir
check_urls "${package_url}"
create_user "pdnsd"
install_pdns
set_conf
set_auto_run "pdnsd"
del_tmp
echo_bye "${my_project}"
}

#local install path
local_path='/usr/local/src'
install_dir="install_$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${install_dir}"  EXIT
main
