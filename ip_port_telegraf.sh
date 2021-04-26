#!/bin/bash
#telegraf端口连接数统计

server=`/bin/ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^172|^127|255$'|head -n1`
#echo $server
hostname=`hostname`

tmp="/tmp/net_count.$$"
#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

#ss -atn4
timetamp=`date -d now +"%s%N"`
ss -4tan|grep -Ev '^State|^LISTEN'|awk '{print $NF,$(NF-1)}'|awk -F':' '{print $1,$NF}' > ${tmp}
ss -4tnl|awk '/^LISTEN/{print $4}'|awk -F':' '{print $2}'|\
xargs -r -i grep -E ' {}$' ${tmp}|sort|uniq -c|\
awk -v hostname="$hostname" -v timetamp="$timetamp" '{print "ip_port_telegraf,hostname="hostname",src_ip="$2",port="$NF" count="$1" "timetamp}'
