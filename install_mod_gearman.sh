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
APT_PACKAGE='libevent-dev uuid-dev libncurses-dev autoconf automake libtool libboost-all-dev gperf chkconfig'

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
	eval "echo Download ${PACKAGE_URL}/${file} fail!;exit 1" &&\
	rm -f /tmp/${file}
done

download_and_check
run_cmds './configure --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc/ --libdir=/usr/lib' 'make' 'make install' 'make install-config'

#nagios setting
nagios_conf='/usr/local/nagios/etc/nagios.cfg'
if [ -f ${nagios_conf} ];then
	mod_gearman_neb_conf='/etc/mod_gearman/mod_gearman_neb.conf'
	grep '#Add Mod_Gearman' ${nagios_conf} >/dev/null 2>&1 ||\
	echo "#Add Mod_Gearman
broker_module=/usr/lib/mod_gearman/mod_gearman.o config=${mod_gearman_neb_conf}" >> ${nagios_conf}
	test -f ${mod_gearman_neb_conf} &&\
	sed -i -r 's/^perfdata=.*/perfdata=yes/;s/^encryption=.*/encryption=no/;s/^key=/#key=/;s/^server=.*/server=127.0.0.1:4730/;s|logfile=.*|logfile=/var/log/mod_gearman/mod_gearman_neb.log|' ${mod_gearman_neb_conf}
	log_path='/var/log/mod_gearman/'
	mkdir -p ${log_path} && chown nagios -R ${log_path}
	test -f /etc/init.d/nagios && /etc/init.d/nagios restart
fi

#mod gearman worker
mod_gearman_worker_conf='/etc/mod_gearman/mod_gearman_worker.conf'
test -f ${mod_gearman_worker_conf} &&\
sed -i -r 's/^encryption=.*/encryption=no/;s/^key=/#key=/;s/^server=.*/server=127.0.0.1:4730/;s/^perfdata=.*/perfdata=yes/;s|logfile=.*|logfile=/var/log/mod_gearman/mod_gearman_worker.log|' ${mod_gearman_worker_conf} 
test -f /etc/init.d/mod_gearman_worker && sed -r -i 's|LOCKFILE=.*|LOCKFILE=/tmp/\$NAME|' /etc/init.d/mod_gearman_worker
/etc/init.d/mod_gearman_worker restart
chkconfig mod_gearman_worker on

grep '#mod gearman' >/dev/null 2>&1 /etc/rc.local ||\
echo "#mod gearman
/usr/local/sbin/gearmand -t 10 -j 0 -d" >> /etc/rc.local
/usr/local/sbin/gearmand -t 10 -j 0 -d

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
