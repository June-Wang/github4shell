#!/bin/bash

ip=`ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`

netstat -nlpt|grep java|awk '{print $4}'|\
awk -F':' '{print $2}'|xargs -r -i lsof -nP -iTCP:{} -sTCP:LISTEN|grep -v 'PID'|\
awk '{print $2,$(NF-1)}'|sed 's/*://'|\
while read pid port
do
    path=`lsof -p ${pid}|grep -E 'log$'|grep -v logs|head -n1|awk '{print $NF}'|grep -oP '^.+/'`
    test -n "$path" && app=`echo "$path"|awk -F'/' '{print $(NF-1)}'`
    test -n "$path" &&\
    eval "echo $ip,$app,$path,$port"
done|sort -u
