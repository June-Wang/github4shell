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
APT_PACKAGE='build-essential apache2 libapache2-mod-php5 libgd2-xpm libgd2-xpm-dev rrdtool libapache2-mod-python'

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
case "${SYSTEM}" in
    centos5|rhel5|rhel6)
	usermod -G nagcmd apache
	GROUP='apache.nagcmd'
	HTTP='httpd'
    ;;
    debian6|debian7)
	usermod -a -G nagcmd www-data
	GROUP='www-data.nagcmd'
	HTTP='apache2'
    ;;
    *)
        echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac
#usermod -G nagcmd apache

#Install nagios-3.5.1.tar.gz
PACKAGE='nagios-3.5.1.tar.gz'

#Create_tmp_dir
create_tmp_dir
download_and_check
run_cmds './configure --with-command-group=nagcmd' 'make all' 'make install' 'make install-init' 'make install-config' 'make install-commandmode' 'make install-webconf'

#Setting auto run
set_auto_run 'nagios'
set_auto_run "${HTTP}"
/etc/init.d/${HTTP} start

#Modify nagios.cfg
nagios_path='/usr/local/nagios'
test -d ${nagios_path} ||\
eval echo "${nagios_path} not exist!;exit 1"

nagios_conf="${nagios_path}/etc/nagios.cfg"
test -f ${nagios_conf} ||\
eval "echo ${nagios_conf} not exist!;exit 1"

sed -i.backup.`date -d now +"%F".$$` 's/^date_format.*$/date_format=iso8601/' ${nagios_conf}

grep 'ADD NEW PATH' ${nagios_conf} >/dev/null 2>&1 ||\
cat << EOF >> ${nagios_conf}
#ADD NEW PATH
cfg_dir=/usr/local/nagios/etc/servers
cfg_dir=/usr/local/nagios/etc/others
cfg_dir=/usr/local/nagios/etc/networks
EOF

mkdir -p /usr/local/nagios/etc/{servers,others,networks}

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
	cmd="curl -s ${yum_url}/${shell}|/bin/bash"
	eval "${cmd}" || eval "echo Run \"${cmd}\" fail!;exit 1"
done

#Setting groups
test -d /var/lib/check_mk/ || mkdir -p /var/lib/check_mk/
test -d /etc/check_mk/ || mkdir -p /etc/check_mk/
chown ${GROUP} -R /var/lib/check_mk/ /etc/check_mk/ /usr/local/nagios/etc

#Setting nagiosadmin passwd
echo -e '
 ***** Attention *****

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
err_log="${TEMP_PATH}/nagios.log"
test -f ${err_log} || touch ${err_log}
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg > ${err_log} 2>&1 && /usr/local/nagios/bin/nagios -d /usr/local/nagios/etc/nagios.cfg ||\
eval "echo Start nagios fail!View detail to ${err_log};exit 1"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
