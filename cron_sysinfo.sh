#!/bin/bash

log_path="/var/log/info"
test -d ${log_path} || mkdir -p ${log_path}

log_name=`date -d "now" +"%F"`
sys_log="${log_path}/sys_${log_name}.log"
net_log="${log_path}/net_${log_name}.log"

rm_name=`date -d "-15 day" +"%F"`
rm_sys_log="${log_path}/sys_${rm_name}.log"
rm_net_log="${log_path}/net_${rm_name}.log"
#uid=`id -u`

test -e ${rm_sys_log} && rm -f ${rm_sys_log}
test -e ${rm_net_log} && rm -f ${rm_net_log}

test -d ${log_path} || mkdir -p ${log_path}
#[ ${uid} -eq 0 ] && chown nagios.nagios -R ${log_path}
echo `date -d "now" +"%F %T"` |tee -a ${net_log} ${sys_log} >/dev/null

cpu_utilization=`ps -eo pcpu,rss,vsize,pid,user -eo "%c"|\
awk '{str="";for (i=2;i<=NF;i++) str=str" "$i;item[str]+=$1}END{for (x in item) if (item[x]>0) print item[x],x}'|\
sort -nr|\
tee -a ${sys_log}|\
awk '{sum+=$1}END{print sum}'`

netstat -nptu >> ${net_log}
