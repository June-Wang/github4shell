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

install_gogoc () {
	install_pre "${package_url}"
	run_cmds 'gmake platform=linux installdir=/usr/local/gogoc install'
	cd ..
}

gogoc_setting () {
	gogoc_conf='/usr/local/gogoc/bin/gogoc.conf'
	test -d ${gogoc_conf} || eval "echo ${gogoc_conf} not exsit! 1>&2"
	echo 'userid=
passwd=
server=anonymous.freenet6.net
auth_method=anonymous
host_type=host
prefixlen=64
if_prefix=
dns_server=
gogoc_dir=/usr/local/gogoc
auto_retry_connect=yes
retry_delay=30
retry_delay_max=300
keepalive=yes
keepalive_interval=30
tunnel_mode=v6anyv4
if_tunnel_v6v4=sit1
if_tunnel_v6udpv4=tun
if_tunnel_v4v6=sit0
client_v4=auto
client_v6=auto
template=linux
proxy_client=no
broker_list=/usr/local/gogoc/tsp-broker-list.txt
last_server=/usr/local/gogoc/tsp-last-server.txt
always_use_same_server=no
log_stderr=0
log_syslog=1
log_filename=/var/log/gogoc.log
log_rotation=yes
log_rotation_size=32
log_rotation_delete=no
syslog_facility=USER' > ${gogoc_conf}
echo 'anon-amsterdam.freenet6.net
anon-taipei.freenet6.net
anon-montreal.freenet6.net' > /usr/local/gogoc/tsp-broker-list.txt
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete!Please type: /usr/local/gogoc/bin/gogoc -y -f /usr/local/gogoc/bin/gogoc.conf" && exit 0
}

main () {
my_project='gogoc'
init_var 'yum.suixingpay.com' 'gogoc-1_2-RELEASE.tar.gz' 'lan'
install_lib "${my_project}" "gcc gcc-c++ glibc-devel openssl openssl-devel crypto-utils make"
make_tmp_dir
check_urls "${package_url}"
install_gogoc
gogoc_setting
del_tmp
echo_bye "${my_project}"
}

#local install path
local_path='/usr/local/src'
install_dir="install_$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${install_dir}"  EXIT
main
