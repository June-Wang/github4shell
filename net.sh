#!/bin/bash

ip="$1"

test -f /etc/redhat-release ||\
eval "echo Not suport this system!;exit 1"

echo ${ip}|grep -oP '\d{1,3}(\.\d{1,3}){3}' >/dev/null 2>&1 ||\
eval "echo ${ip} not ip address!;exit 1"

net=`echo ${ip}|grep -oE '^.*\.'`
now=`date -d now +"%F-%H-%M-%S"`
version=`grep -oP '\d' /etc/redhat-release |head -n1`

if [ "${version}" == '6' ];then
test -f /etc/sysconfig/network-scripts/ifcfg-eth0 && \
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /tmp/ifcfg-eth0.bak.${now}

echo "DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=${ip}
PREFIX=24
GATEWAY=${net}254
" > /etc/sysconfig/network-scripts/ifcfg-eth0

sed -r -i "s/^HOSTNAME.*$/HOSTNAME=HOST${host}/" /etc/sysconfig/network
sed -r -i "s/127.0.0.1   localhost/127.0.0.1  ${host} localhost/" /etc/hosts
test -f /etc/udev/rules.d/70-persistent-net.rules &&\
grep '^#' /etc/udev/rules.d/70-persistent-net.rules |sed '/PCI device/d' > /etc/udev/rules.d/70-persistent-net.rules
fi

if [ "${version}" == '7' ];then
test -f /etc/sysconfig/network-scripts/ifcfg-eno16780032 &&\
cp /etc/sysconfig/network-scripts/ifcfg-eno16780032 /etc/sysconfig/network-scripts/ifcfg-ens192 &&\
mv /etc/sysconfig/network-scripts/ifcfg-eno16780032 /tmp/ifcfg-eno16780032.bak.${now}
sed -i 's/eno16780032/ens192/g' /etc/sysconfig/network-scripts/ifcfg-ens192
sed -i -r "s|^IPADDR=.*$|IPADDR=${ip}|g;s|^GATEWAY=.*|GATEWAY=${net}254|g" /etc/sysconfig/network-scripts/ifcfg-ens192
fi

test -f /tmp/net.sh && rm -f /tmp/net.sh
test -f /etc/rc.d/rc.local && chmod +x /etc/rc.d/rc.local

echo '
curl -s http://yum.server.local/shell/init.sh|/bin/bash
sed -i "/init.sh/d;/sed/d" /etc/rc.local
sed -i "/init.sh/d;/sed/d" /etc/rc.d/rc.local
' >> /etc/rc.local

reboot
