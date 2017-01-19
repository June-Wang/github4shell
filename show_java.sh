#!/bin/bash

ip=`ip address show|awk '/inet/{print $2}'|grep -oP '^.+\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|tail -n1`


netstat -nlpt|grep java|awk '{print $4,$NF}'|\
grep -Ev '^127'|sed -r 's/^0.*://;s|/| |'|sort -nk2|\
while read port pid java
do
        pro=`ps -eo pid,args|grep "${pid}"|grep -oP '=/.+?/.+?/'|grep -vP '\s+?'|sed 's/=//'|sort -u`
        echo -en "port: ${port}\tpid: ${pid}\ttask: ${pro}\n"
done
