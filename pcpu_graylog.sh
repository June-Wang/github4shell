#!/bin/bash

dev_name="$1"
graylog_server="$2"

test -z ${dev_name} &&\
eval "echo dev_name is null!;exit 1"

hostname=`hostname`
ip=`/sbin/ip addr list|grep -E "${dev_name}$"|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
now=`date -d now +"%F %T"`

timetamp=`date -d now +"%s%N"`
ps -eo pcpu,rss,vsize,pid,user -eo "%c"|\
awk '{str="";for (i=2;i<=NF;i++) str=str" "$i;item[str]+=$1}END{for (x in item) if (item[x]>0) print item[x],x}'|\
sort -nr|grep -Ev ':|\]$'|\
while read pcpu rss vsize pid user args
do
    echo "{#version#: #1.1#, #host#: #${hostname}#,#short_message#: #pcpu_info#,#_server#:#${ip}#,#_user#:#${user}#,#_proc_name#:#${args}#,#_pid#:#${pid}#,#_pcpu#:${pcpu},#_mem_rss#:${rss},#_vsize#:${vsize}}"
done |sed 's/#/\"/g'|\
while read line
do
    echo -n ${line}|nc -w1 -u ${graylog_server} 12201
    #echo  ${line}
done
