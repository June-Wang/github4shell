#!/bin/bash

ip="$1"
net=`echo ${ip}|awk -F'.' '{print $3}'`
host=`echo ${ip}|awk -F'.' '{print $4}'`

test -f /etc/sysconfig/network-scripts/ifcfg-eth0 && \
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /tmp/ifcfg-eth0.$$

sed  "s/_NET_/${net}/g;s/_IP_/${ip}/g" /tmp/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-eth0

sed -r -i "s/^HOSTNAME.*$/HOSTNAME=HOST${host}/" /etc/sysconfig/network
sed -r -i "s/127.0.0.1   localhost/127.0.0.1  ${host} localhost/" /etc/hosts
#echo "hostname ${hostname}" >> /etc/rc.local
test -f /etc/udev/rules.d/70-persistent-net.rules &&\
grep '^#' /etc/udev/rules.d/70-persistent-net.rules |sed '/PCI device/d' > /etc/udev/rules.d/70-persistent-net.rules

test -f /tmp/net.sh && rm -f /tmp/net.sh

echo '
curl -s http://yum.server.local/shell/init.sh|/bin/bash
sed -i "/init.sh/d;/sed/d" /etc/rc.local
' >> /etc/rc.local

reboot
