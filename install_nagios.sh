#!/bin/bash

#SET ENV
YUM_SERVER='yum.suixingpay.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='httpd php gcc glibc glibc-common gd gd-devel openssl-devel xinetd'
APT_PACKAGE='build-essential'

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
set_install_cmd 'lan'

#Created user
create_user "nagios" "bash"

#Set group
groupadd nagcmd
usermod -G nagcmd nagios
usermod -G nagcmd apache

#Install nagios-3.5.1.tar.gz
PACKAGE='nagios-3.5.1.tar.gz'

#Create_tmp_dir
create_tmp_dir
download_and_check
run_cmds './configure --with-command-group=nagcmd' 'make all' 'make install' 'make install-init' 'make install-config' 'make install-commandmode' 'make install-webconf'

#Setting auto run
set_auto_run 'nagios'
set_auto_run 'httpd'
/etc/init.d/httpd start

#Setting nagios alias
grep 'Setting Nagios alias' ~/.bashrc >/dev/null 2>&1 ||\
cat << EOF >> ~/.bashrc
#Setting Nagios alias
alias chknagios='/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'
alias chgnagiospwd='/usr/bin/htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin'
alias nagiosstatus='/usr/local/nagios/bin/nagiostats'
EOF

#Install nagios-plugins nrpe
yum_url="http://${YUM_SERVER}/shell"

cmds=(
install_nagios-plugins.sh
install_nrpe.sh
)

for shell in "${cmds[@]}"
do
	cmd="curl -s ${yum_url}/${shell}|sh"
	eval "${cmd}" || eval "echo Run \"${cmd}\" fail!;exit 1"
done

#Setting nagiosadmin passwd
echo -e ' ***** Attention *****

 Setting nagiosadmin passwd:
\t/usr/bin/htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin'

#Check nagios config
echo -e '
 Check nagios config:
\t/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'

#Start Nagios
echo -e '
 Start nagios:
\t/usr/local/nagios/bin/nagios -d /usr/local/nagios/etc/nagios.cfg'

#View nagios status
echo -e '
 View nagios status:
\t/usr/local/nagios/bin/nagiostats
'

#Start nagios
err_log=" ${TEMP_PATH}/nagios.log"
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg > ${err_log} 2>&1 && /usr/local/nagios/bin/nagios -d /usr/local/nagios/etc/nagios.cfg ||\
eval "echo Start nagios fail!View detail to ${err_log};exit 1"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
