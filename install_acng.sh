#!/bin/bash

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

install_acng () {
        download_file "${PACKAGE_URL}"
        check_file "${PACKAGE}"
#        run_cmds 'make' 'make acng' 'make in.acng acngfs'
        run_cmds 'make'
        ACNG_CONFIG_DIR='/etc/apt-cacher-ng'
        mv conf ${ACNG_CONFIG_DIR}
	cp ${ACNG_CONFIG_DIR}/backends_ubuntu.default ${ACNG_CONFIG_DIR}/backends_ubuntu
	cp ${ACNG_CONFIG_DIR}/backends_debian.default ${ACNG_CONFIG_DIR}/backends_debian
	cp build/apt-cacher-ng /usr/local/sbin/
	cp build/acngfs /usr/local/sbin/
	cp build/in.acng /usr/local/sbin/
	cp expire-caller.pl /etc/cron.daily/apt-cacher-ng
	chmod +x /etc/cron.daily/apt-cacher-ng
        local cache_dir='/var/cache/apt-cacher-ng'
        test -d ${cache_dir} || mkdir -p ${cache_dir}
        local log_dir='/var/log/apt-cacher-ng'
        test -d ${log_dir} || mkdir -p ${log_dir}
	local socket_dir='/var/run/apt-cacher-ng'
	test -e ${socket_dir} || mkdir -p ${socket_dir}
#	chown -R apt-cacher-ng:apt-cacher-ng ${cache_dir}
	chmod -R a+rX,g+rw,u+rw ${log_dir}
        cd ..
}

acng_setting () {
test -d ${ACNG_CONFIG_DIR} || mkdir -p ${ACNG_CONFIG_DIR}
echo 'http://mirrors.163.com/debian-security/
http://mirrors.suho.com/debian-security/
http://mirror.neu.edu.cn/debian-security/
http://mirrors.ustc.edu.cn/debian-security/' > ${ACNG_CONFIG_DIR}/debian-security_mirrors

echo 'http://mirrors.163.com/debian/
http://mirrors.suho.com/debian/
http://mirror.neu.edu.cn/debian/
http://mirrors.ustc.edu.cn/debian/' > ${ACNG_CONFIG_DIR}/debian_mirrors

echo 'http://mirrors.163.com/centos/
http://mirrors.suho.com/centos/
http://mirror.neu.edu.cn/centos/
http://centos.ustc.edu.cn/centos/' > ${ACNG_CONFIG_DIR}/centos_mirrors

echo 'http://mirrors.ustc.edu.cn/fedora/epel/
http://mirrors.sohu.com/fedora-epel/
http://mirror.neu.edu.cn/fedora/epel/' > ${ACNG_CONFIG_DIR}/epel_for_china_mirrors

echo 'CacheDir: /var/cache/apt-cacher-ng
LogDir: /var/log/apt-cacher-ng
Port:3142
Remap-debianrep: file:debian-security_mirrors /debian-security ; file:debian-security_mirrors # Debian Archives
Remap-debrep: file:debian_mirrors /debian ; file:debian_mirrors # Debian Archives
Remap-uburep: file:ubuntu_mirrors /ubuntu ; file:backends_ubuntu # Ubuntu Archives
Remap-cygwin: file:cygwin_mirrors /cygwin # ; file:backends_cygwin # incomplete, please create this file or specify preferred mirrors here
Remap-sfnet:  file:sfnet_mirrors # ; file:backends_sfnet # incomplete, please create this file or specify preferred mirrors here
Remap-alxrep: file:archlx_mirrors /archlinux # ; file:backend_archlx # Arch Linux
Remap-fedora:  file:fedora_mirrors # Fedora Linux
Remap-epel:   file:epel_for_china_mirrors  /epel ;file:epel_for_china_mirrors
Remap-centos:   file:centos_mirrors  /centos ; file:centos_mirrors
Remap-slrep:  file:sl_mirrors # Scientific Linux
ReportPage: acng-report.html
ExTreshold: 4
WfilePattern = (^|.*?/)(Release|InRelease|Release\.gpg|(Packages|Sources)(\.gz|\.bz2|\.lzma|\.xz)?|Translation[^/]*(\.gz|\.bz2|\.lzma|\.xz)?|MD5SUMS|SHA1SUMS|.*\.xml|.*\.db\.tar\.gz|.*\.files\.tar\.gz|.*\.abs\.tar\.gz|[a-z]+32.exe)$|/dists/.*/installer-.*/images/.*' > ${ACNG_CONFIG_DIR}/acng.conf

}

set_auto_run () {
        local auto_file='/etc/rc.local'
        grep "${MY_PROJECT}" ${auto_file} >/dev/null 2>&1 || local setting='no'
        if [ "${setting}" = 'no' ];then
                echo "apt-cacher-ng -c ${ACNG_CONFIG_DIR}" >> ${auto_file}
        fi
}

echo_bye () {
        echo "Install ${PACKAGE} complete! If you run this program, please type: apt-cacher-ng -c ${ACNG_CONFIG_DIR}" && exit 0
}

main () {
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"
PACKAGE_URL="http://${YUM_SERVER}/tools/${PACKAGE}"
check_system
#create_user
create_tmp_dir
set_yum 'lan'
install_yum_package "${YUM_PACKAGE}"
install_acng
set_auto_run
del_tmp
acng_setting
echo_bye
}

#SET TEMP PATH
TEMP_PATH='/usr/local/src'
INSTALL_DIR="install_$$"

#SET GLOBAL VAR
MY_PROJECT='apt-cacher-ng'
PACKAGE='apt-cacher-ng-0.7.7.tar.gz'
YUM_SERVER='yum.suixingpay.com'
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++ zlib zlib-devel bzip2-libs bzip2-devel pkgconfig fuse fuse-devel'

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT
main
