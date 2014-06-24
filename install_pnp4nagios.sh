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
YUM_PACKAGE='php-gd rrdtool-perl rrdtool'
#APT_PACKAGE='build-essential'

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
#Check nagios user
id nagios >/dev/null 2>&1 ||\
eval "echo nagios user not exist!;exit 1"

#Check nagios path
test -d /usr/local/nagios/ ||\
eval "echo nagios not installed!;exit 1"

#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
set_install_cmd 'lan'

#Install pnp4nagios-0.6.22.tar.gz
PACKAGE='pnp4nagios-0.6.22.tar.gz'

#Create_tmp_dir
create_tmp_dir
download_and_check
run_cmds './configure --with-nagios-user=nagios \
--with-nagios-group-nagios \
--with-rrdtool=/usr/bin/rrdtool \
--with-perfdata-dir=/usr/local/nagios/share/perfdata/' 'make all' 'make install' 'make install-webconf' 'make install-config' 'make install-init' 'make fullinstall'

#Modify /usr/local/nagios/etc/nagios.cfg
nagios_conf='/usr/local/nagios/etc/nagios.cfg'
test -f ${nagios_conf} ||\
eval "echo ${nagios_conf} not exist!;exit 1"

grep 'Bulk Mode with NPCD:' ${nagios_conf} >/dev/null 2>&1 ||\
cat << EOF >> ${nagios_conf}
#Bulk Mode with NPCD:
process_performance_data=1

#
# service performance data
#
service_perfdata_file=/usr/local/pnp4nagios/var/service-perfdata
service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::\$TIMET\$\tHOSTNAME::\$HOSTNAME\$\tSERVICEDESC::\$SERVICEDESC\$\tSERVICEPERFDATA::\$SERVICEPERFDATA\$\tSERVICECHECKCOMMAND::\$SERVICECHECKCOMMAND\$\tHOSTSTATE::\$HOSTSTATE\$\tHOSTSTATETYPE::\$HOSTSTATETYPE\$\tSERVICESTATE::\$SERVICESTATE\$\tSERVICESTATETYPE::\$SERVICESTATETYPE\$
service_perfdata_file_mode=a
service_perfdata_file_processing_interval=15
service_perfdata_file_processing_command=process-service-perfdata-file

#
# host performance data starting with Nagios 3.0
# 
host_perfdata_file=/usr/local/pnp4nagios/var/host-perfdata
host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::\$TIMET\$\tHOSTNAME::\$HOSTNAME\$\tHOSTPERFDATA::\$HOSTPERFDATA\$\tHOSTCHECKCOMMAND::\$HOSTCHECKCOMMAND\$\tHOSTSTATE::\$HOSTSTATE\$\tHOSTSTATETYPE::\$HOSTSTATETYPE\$
host_perfdata_file_mode=a
host_perfdata_file_processing_interval=15
host_perfdata_file_processing_command=process-host-perfdata-file
EOF

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
