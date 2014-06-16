#!/bin/bash

for file in /proc/sys/net/ipv4/conf/*/rp_filter
do
	echo 1 > ${file}
done

iptables_cmd='/sbin/iptables'
${iptables_cmd} -F
${iptables_cmd} -A INPUT -p all -m state --state INVALID -j DROP
${iptables_cmd} -A INPUT ! -p udp -s 224.0.0.0/4 -j DROP
${iptables_cmd} -A INPUT ! -i lo -s 127.0.0.0/8 -j DROP
