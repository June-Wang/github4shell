#!/bin/bash

tmp_ps="/tmp/ps.$$"
tmp_net="/tmp/net.$$"

trap "exit 1"       HUP INT PIPE QUIT TERM
trap "test -f ${tmp_ps} && rm -f ${tmp_ps}; test -f ${tmp_net} && rm -f ${tmp_net}"  EXIT

ps -eo pid,args > ${tmp_ps}
#netstat -nltp|grep java
netstat -nltp 2>/dev/null|awk '$NF~/java/{print $4,$NF}'|awk -F'[:|/]' '{print $(NF-1)}' > ${tmp_net}

find /data/ -type f -name 'appctl.sh' 2>/dev/null|\
awk -F'/' '{print $(NF-1),$0}'|sed 's/appctl.sh$//'|\
while read app path
do
    pid=`grep "${app}" ${tmp_ps}|awk '{print $1}'`
    echo "${app} ${path} ${pid}"
done|\
while read app path pid
do
    port=`grep -E "${pid}$" ${tmp_net}|awk '{print $1}'|grep -P '^\d{4}$|^2088\d+$'`
    app=`echo "${app}                      "|grep -oP '^.{1,40}'`
    echo -en "${pid}\t${port}\t${app}${path}\n"
done|\
sort -nk2|sed '1i\pid\tport\tapp\tpath'
