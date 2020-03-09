#!/bin/bash

grep proxy_pass /data/config/nginx-finance-web/conf.d/*.conf|grep -Ev 'wiki|graylog|mk|#|zabbix'|\
awk '{print $1,$NF}'|sort -u|awk -F'/' '{print $(NF-2),$NF}'|\
sed 's/.conf: http://;s/.conf: https://;s/.$//'|grep -E '[0-9]$'|grep ':'|\
sed 's/:/ /'|\
while read domain ip port
do
    echo "check_http_${domain} /usr/local/nagios-plugins/check_http -4 -H ${ip} -p ${port} -w2 -c3 -t4"
done
