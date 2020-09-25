#!/bin/bash

#ip=`ip addr show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127\.|255'|awk '{ORS=";";print}'`
ip=`ip addr show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127\.|255'|head -n1`
host_name=`hostname`

my_date=`date +"%Y-%m-%d  %H:%M:%S"`
ls /etc/redhat-release >/dev/null 2>&1 && \
os_profie='/etc/redhat-release' || \
os_profie='/etc/issue.net'
#ls /etc/debian_version >/dev/null 2>&1 && os_profie='/etc/debian_version'

operating=`head -n1 ${os_profie}`
machine=`uname -m`
mem_info=`free -m|awk '/Mem:/ {print $2,"MB"}'`
cpu_info=`awk -F':[ ]+' '/model name/ {print $2}' /proc/cpuinfo|head -n 1|sed -r 's/[ ]+/ /g'`
cpu_num=`grep 'processor' /proc/cpuinfo |wc -l`
#disk_info=`df -h|awk '/root/{print $2}'`
#disk_info=`df -h|awk 'NF<2{ORS=" "}NF>2{ORS="\n"}{print}'|awk '/\/$/{print $2}'`
disk_info=`df -h |grep -Ev 'tmpfs|Filesystem|devtmpfs|boot'|awk '$2~/G$/{print $2}'|sed 's/G//'|awk '{sum+=$1}END{print sum"G"}'`
swap_info=`free -m|awk '/Swap/{print $2" Mb"}'`

echo -en "${ip}\t${host_name}\t${cpu_info}\t${cpu_num}\t${mem_info}\t${disk_info}\t${swap_info}\t${operating}\t${machine}\n"
