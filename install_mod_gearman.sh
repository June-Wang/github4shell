#!/bin/bash

#SET ENV
YUM_SERVER='yum.lefu.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++ ncurses-devel'
APT_PACKAGE='libevent-dev uuid-dev libncurses-dev autoconf automake libtool libboost-all-dev gperf'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#Install mod_gearman-1.4.12.tar.gz
PACKAGE='mod_gearman-1.4.12.tar.gz'
create_tmp_dir

#install libgear pkg
files=(
multiarch-support_2.13-38+deb7u3_amd64.deb
libgearman6_0.33-2_amd64.deb
libgearman-dev_0.33-2_amd64.deb
)

for file in "${files[@]}"
do
	echo -en "Install ${file} ...... "
	wget -q "${PACKAGE_URL}/${file}" -O /tmp/${file} &&\
	run_cmds "dpkg -i /tmp/${file}" ||\
	eval "echo Download ${PACKAGE_URL}/${file} fail!;exit 1"
done

download_and_check
run_cmds './configure --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc/ --libdir=/usr/lib' 'make' 'make install' 'make install-config'

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
