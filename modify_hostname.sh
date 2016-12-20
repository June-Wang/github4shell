#!/bin/bash

ip=`ip address show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$|\.0$'`

host_name=`echo $ip|awk -F'.' '{print "HOST"$NF}'`

#echo ${host_name}

test -f /etc/sysconfig/network && sed -r -i "s/^HOSTNAME.*/HOSTNAME=${host_name}/" /etc/sysconfig/network

test -f /etc/hosts && sed -r -i "/^${ip}/d" /etc/hosts

grep "${host_name}" /etc/hosts >/dev/null 2>&1 ||\
echo "${ip} ${host_name}" >> /etc/hosts

hostname ${host_name}
