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

install_pcre () {
	install_pre "${package_url}"
	run_cmds './configure' 'make' 'make install'
	cd ..
}

install_varnish () {
	install_pre "${package_url}"
#	export PKG_CONFIG_PATH=/usr/local/pcre/lib/pkgconfig
	export echo=echo
	run_cmds 'sh autogen.sh' './configure --enable-dependency-tracking  --enable-debugging-symbols  --enable-developer-warnings' 'make check' 'make' 'make install'
	test -e /etc/rc.d/init.d/varnish || cp redhat/varnish.initrc /etc/rc.d/init.d/varnish
	test -e /etc/sysconfig/varnish || cp redhat/varnish.sysconfig  /etc/sysconfig/varnish
	test -e /usr/bin/varnish_reload_vcl || cp redhat/varnish_reload_vcl /usr/bin/
	test -e /usr/sbin/varnishd || cp /usr/local/sbin/varnishd /usr/sbin/varnishd
	mkdir -p /etc/varnish/
	mkdir -p /var/lib/varnish/ && chown varnish.varnish -R /var/lib/varnish/
	test -e /etc/varnish/default.vcl || cp /usr/local/etc/varnish/default.vcl /etc/varnish/
	test -e /etc/varnish/secret || echo "password" > /etc/varnish/secret
	test -e /usr/bin/varnish_reload_vcl && sed -i 's#VARNISHADM="varnishadm#VARNISHADM="/usr/local/bin/varnishadm#' /usr/bin/varnish_reload_vcl
	test -e /etc/sysconfig/varnish && sed -i 's/-S ${VARNISH_SECRET_FILE}/#-S ${VARNISH_SECRET_FILE}/' /etc/sysconfig/varnish
	cd ..
}

set_auto_run () {
	chkconfig --add varnish
	chkconfig varnish on
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete! Please type : /etc/init.d/${program} start " && exit 0
}

main () {
my_project='varnish'
#init_var 'yum.suixingpay.com' 'pcre-8.30.tar.gz' 'lan'
init_var 'yum.suixingpay.com' 'varnish-3.0.2.tar.gz' 'lan'
install_lib "${my_project}" "automake autoconf libtool ncurses-devel libxslt groff pcre-devel pkgconfig gcc gcc-c++ make"
make_tmp_dir
create_user "${my_project}"
check_urls "${package_url}"
#install_pcre
check_urls "${package_url}"
install_varnish
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
