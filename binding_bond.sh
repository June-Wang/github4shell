#!/bin/bash

NIC1="$1"
NIC2="$2"
BOND="$3"
BOND_IP="$4"

usage () {
	echo -en "$0 [dev1] [dev2] [bond] [IP]\nFor example: $0 eth0 eth1 bond0 192.168.10.18\n" 1>&2
	exit 1
}

if [ -z "${NIC1}" -o -z "${NIC2}" -o -z "${BOND}" -o -z "${BOND_IP}" ];then
	usage
fi

NIC_DEV=(
${NIC1}
${NIC2}
)

for nic in "${NIC_DEV[@]}"
do
	ifconfig -a|grep "${nic}" >/dev/null 2>&1 ||\
	eval "echo \"${nic} not exist!please tap ifconfig -a\" 1>&2;exit 1"
done

echo "${BOND_IP}"|grep -oP '^\d{1,3}(\.\d{1,3}){3}$' ||\
eval "echo \"${BOND_IP} not a ip!\" 1>&2;exit 1"

my_time=`date -d now +"%F_%H-%M-%S"`

for nic in "${NIC_DEV[@]}"
do
        nic_conf="/etc/sysconfig/network-scripts/ifcfg-${nic}"
        if [ -f "${nic_conf}" ];then
                file_name=`basename ${nic_conf}`
                cp ${nic_conf} /root/${file_name}.${my_time}
                echo "DEVICE=${nic}
ONBOOT=yes
MASTER=${BOND}
SLAVE=yes
BOOTPROTO=none" > ${nic_conf}
        fi
done

bond_conf="/etc/sysconfig/network-scripts/ifcfg-${BOND}"
if [ -f "${bond_conf}" ];then
        file_name=`basename ${bond_conf}`
        cp ${bond_conf} /root/${file_name}.${my_time}
fi

net=`echo "${BOND_IP}"|grep -oP '(\d{1,3}\.){3}'`
network="${net}0"
gateway="${net}1"

echo "DEVICE=${BOND}
IPADDR=${BOND_IP}
NETWORK=${network}
NETMASK=255.255.255.0
GATEWAY=${gateway}
BOOTPROTO=static
ONBOOT=yes" >${bond_conf}

mod_conf='/etc/modprobe.d/binding.conf'

if [ -f "${mod_conf}" ];then
        grep -E "^#-=SET ${BOND} BEGIN=-" ${mod_conf} >/dev/null 2>&1 || set_bond='no'
        if [ "${set_bond}" == 'no' ];then
        echo "
#-=SET ${BOND} BEGIN=-
alias ${BOND} bonding
options ${BOND} miimon=100 mode=1" >> ${mod_conf}
        fi
fi

modprobe bonding
service network restart
cat /proc/net/bonding/${BOND}
ifconfig ${BOND}
