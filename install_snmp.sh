#!/bin/bash

check_system (){
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
                YUM_SOURCE_NAME='centos5-lan'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                YUM_SOURCE_NAME='RHEL5-lan'
                ;;
	'Red Hat Enterprise Linux Server release 6'*)
                SYSTEM='rhel6'
                yum_source_name='RHEL6-lan'
                repo_file='/etc/yum.repos.d/RHEL6-lan.repo'
                ;;
        'Debian GNU/Linux 6'*)
                SYSTEM='debian6'
                ;;
        'Debian GNU/Linux 7'*)
                SYSTEM='debian7'
                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

set_install_cmd () {
case "${SYSTEM}" in
        centos5|rhel5|rhel6)
                INSTALL_CMD='yum --skip-broken --nogpgcheck'
                CONFIG_CMD='chkconfig'
        ;;
        debian6|debian7)
                INSTALL_CMD='aptitude'
                CONFIG_CMD='chkconfig'
                eval "${INSTALL_CMD} install -y ${CONFIG_CMD}" >/dev/null 2>&1 || eval "echo ${install_cmd} fail! 1>&2;exit 1"
        ;;
        *)
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac
}

install_snmpd_for_redhat () {
${INSTALL_CMD} -y install net-snmp >/dev/null 2>&1 || install_snmp='fail'
}

install_snmpd_for_debian () {
${INSTALL_CMD} -y install snmpd >/dev/null 2>&1 || install_snmp='fail'
}

install_snmpd () {
case "${INSTALL_CMD}" in
        'yum'*)
                test -e /etc/init.d/snmpd || install_snmpd_for_redhat
        ;;
        'apt'*)
                test -e /etc/init.d/snmpd || install_snmpd_for_debian
        ;;
        *)
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac
}

check_install_status () {
if [ "${install_snmp}" = 'fail' ];then
        echo "${INSTALL_CMD} not available! install snmpd fail!" 1>&2
        exit 1
fi
}

set_snmpd_config () {
snmp_conf='/etc/snmp/snmpd.conf'
test -z "${community}" && community='public'
test -z "${location}" && location='localhost'
test -z "${contact}" && contact='admin'
test -z "${email}" && email='admin@local'

if [ ! -f "${snmp_conf}" ];then
        echo "${snmp_conf} not exist!" 1>&2
        exit 1
else
        grep -E '^#SET SNMP _END_' >/dev/null 2>&1 "${snmp_conf}" || set_snmp='fail'
        if [ "${set_snmp}" = "fail" ];then
                local my_date=`date -d 'now' +'%Y%m%d%H%M%S'`
                cp "${snmp_conf}" "${snmp_conf}.${my_date}.$$"
                echo "#SET SNMP _BEGIN_
com2sec notConfigUser  default       ${community}
group   notConfigGroup v1           notConfigUser
group   notConfigGroup v2c           notConfigUser
view    systemview    included   .1
access  notConfigGroup \"\"      any       noauth    exact  systemview none none
syslocation ${location}
syscontact ${contact} (${email})
dontLogTCPWrappersConnects yes
#SET SNMP _END_" >${snmp_conf}

                /etc/init.d/snmpd restart
                ${CONFIG_CMD} snmpd on
        fi
fi
}

syslog_off () {
snmp_options='/etc/sysconfig/snmpd.options'
test -f "${snmp_options}.bak.old" && exit 1

if [ -f "${snmp_options}" ];then
        cp ${snmp_options} ${snmp_options}.bak.old
        echo 'OPTIONS="-Lf /dev/null -p /var/run/snmpd.pid -a"' > ${snmp_options}
#        /etc/init.d/snmpd restart
fi
}

echo_bye () {
        echo "Install snmpd complete!" && exit 0
}

main () {
check_system
set_install_cmd
install_snmpd
check_install_status
syslog_off
set_snmpd_config
echo_bye
}

location='BJ'
contact='admin'
email='admin@bj.com'
community='lefu'
main
