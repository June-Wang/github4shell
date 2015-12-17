#!/bin/bash

[ -n "$1" ] && ip="$1" || \
#ip=`/sbin/ifconfig eth0|awk -F'[\t ]+[a-z|A-Z]+:' '/inet addr:/ {print $2}'`
ip=`ifconfig -a|grep -E -A1 'eth0|bond0'|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127\.|255'`
host_name=`hostname`
file=`basename "$0"|awk -F'.' '{print $1}'`
tmp="/tmp/${ip}.${file}"

my_date=`date +"%Y-%m-%d  %H:%M:%S"`
operating=`awk -F'\' 'NR==1{print $1}' /etc/issue`
machine=`uname -m`
mem_info=`free -m|awk '/Mem:/ {print $2,"MB"}'`
cpu_info=`awk -F':[ ]+' '/model name/ {print $2}' /proc/cpuinfo|head -n 1|perl -pe 's/\s+/ /g'`
cpu_num=`grep 'processor' /proc/cpuinfo |wc -l`
#disk=`fdisk -l|grep -Ev '/dev/dm|Disk identifier'|awk -F'[,:]' 'BEGIN{ORS=";"}/Disk/{gsub(" ","");print $2}'`
#disk_info=`df -hP|awk 'BEGIN{OFS="\t"};/^\/dev\//{print $NF,$2,$3,$4,$5}'`
#gate_way=`route -n|awk '/^0.0.0.0/{print $2}'`
disk_info=`fdisk -l|grep -Ev '/dev/dm|Disk identifier'|awk -F'[,:]' 'BEGIN{ORS=";"}/Disk/{gsub(" ","");print $2}'`
#line=`perl -e 'print "-" x 80 . "\n";'`

echo -en "${ip}\t${host_name}\t${cpu_info}\t${cpu_num}\t${mem_info}\t${disk_info}\t${operating}\t${machine}\n"
