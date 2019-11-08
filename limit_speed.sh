#!/bin/bash

tc qdisc add dev eth0 root handle 1: htb default 1    
tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbps    
tc class add dev eth0 parent 1:1 classid 1:5 htb rate 512Kbit ceil 768Kbit prio 1
#flowid 要和 classid匹配           
tc filter add dev eth0 parent 1:0 prio 1 protocol ip handle 5 fw flowid 1:5    
#iptables -A OUTPUT -p tcp -m multiport --sports 80,443 -j MARK --set-mark 5
