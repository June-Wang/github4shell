#!/bin/bash

dev_name="$1"
test -z ${dev_name} &&\
eval "echo dev_name is null!;exit 1"

hostname=`hostname`
ip=`/sbin/ip addr list|grep -E "${dev_name}$"|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
timetamp=`date -d now +"%s%N"`

netstat -ant|grep -Ev 'LISTEN|State$'|\
awk '{print $(NF-2),$(NF-1),$(NF)}'|\
sed -r 's/:/\t/g'|\
awk -v hostname="${hostname}" -v ip="${ip}" -v timetamp="${timetamp}" \
'NF==5{print "netstat_info,host="hostname",server="ip",local_ip="$1",local_port="$2",foreign_ip="$3",foreign_port="$4",status="$5" count=1 "timetamp}'
