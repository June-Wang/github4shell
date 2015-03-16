#!/bin/bash

mrpe_conf='/etc/check_mk/mrpe.cfg'
test -f ${mrpe_conf} && sed -r -i '/check_tcp_.+$/d' ${mrpe_conf}
netstat -ntlp 2>/dev/null|grep 'java'|grep -v '127.0.0.1'|awk '{print $4,$NF}'|grep -oP '\d+\s\d+'|\
while read port pid
do
        echo -en "$port\t"
        ps -eo pid,args|grep "$pid"|grep -oP '/opt/.[^/| ]*/'|grep -Ev 'JDK|grep'|sort -u
done|sort -u|sort -k2|\
while read port path
do
        serv_name=`echo $path|awk -F'/' '{print $3}'`
        echo "check_tcp_${serv_name}_${port} /usr/local/nagios/libexec/check_tcp -w 2 -c 3 -t 4 -p ${port}"
done >> ${mrpe_conf}
