#!/bin/bash

graylog_server='127.0.0.1'
user='admin'
passwd='passwd123'
url="http://${graylog_server}:9000/api/search/universal/absolute/export?query=streams%3A"
streams='5ba331bfdd033702933c2e20'
from=`date -d '-2min' +"%F %T"|sed -r 's/ /%20/g;s/:/%3A/g'`
to=`date -d '-1min' +"%F %T"|sed -r 's/ /%20/g;s/:/%3A/g'`
field='timestamp,guardian_api,request_time'
fields=`echo ${field}|sed -r 's/,/%2C/g'`

tmp="/tmp/coll_guardian_api.$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

curl -u ${user}:${passwd} -s http://${graylog_server}:9000/api/system|\
grep -oP '"lb_status":.+?,'| grep alive >/dev/null 2>&1 ||\
eval "echo 请求graylog失败!;exit 1"

curl -u ${user}:${passwd} -s "${url}${streams}&from=${from}&to=${to}&fields=${fields}" |\
awk -F',' 'NF>2{print $1,$2,$3}' |\
sed -r '1d;s/"//g' |\
while read datetime api request
do
    test -z "${request}" && continue
    #test -z "${api}" && continue
    timetamp=`date -d "${datetime}" +"%s%N"`
    echo "guardian_api,api=${api} request_time=${request} ${timetamp}" >> ${tmp}
done
    #timetamp=`date -d "${datetime}" +"%s"`
    #echo -en "${timetamp}\t${api}\t${request}\n"
    #curl -i -XPOST 'http://localhost:8086/write?db=dbname&u=dbuser&p=dbpasswd&precision=s' --data-binary "guardian_api,api='${api}' request_time=${request} ${timetamp}"
    #curl -i -XPOST 'http://localhost:8086/write?db=dbname&u=dbuser&p=dbpasswd' --data-binary "guardian_api,api='${api}' request_time=${request} ${timetamp}"
#cat ${tmp}
test -s ${tmp} &&\
curl -i -XPOST 'http://localhost:8086/write?db=dbname&u=dbuser&p=dbpasswd' --data-binary @${tmp}
