#!/bin/bash

graylog_server='172.21.194.178'
user='admin'
passwd='passwd'
url="http://${graylog_server}:9000/api/search/universal/absolute/export?query=streams%3A"
streams='5b7d18922994a67297060c19'
#streams='5b5d91672994a61d81a0b3ae'
from=`date -d '-2min' +"%F %T"|sed -r 's/ /%20/g;s/:/%3A/g'`
to=`date -d '-1min' +"%F %T"|sed -r 's/ /%20/g;s/:/%3A/g'`
fields='message'

file_name=`date -d now +"%F_%T.csv"|sed 's/:/-/g'`
tmp="/tmp/${file_name}"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}; test -f ${tmp}.gz && rm -f ${tmp}.gz"  EXIT

cmd="mutt -s ${subj} -e 'set realname=advai_alert'"

curl -u ${user}:${passwd} -s "${url}${streams}&from=${from}&to=${to}&fields=${fields}" > ${tmp} ||\
eval "echo 请求graylog失败!;exit 1"

test -s ${tmp} && head10=`head -n10 ${tmp}` && num=`wc -l ${tmp}|awk '{print $1}'`

test -s ${tmp} && gzip ${tmp} &&\
echo -en "${head10}\n共计:${num}条,更多内容详见附件!\n系统自动发送,请勿直接回复.\n"|\
mutt -s '[mk]finance环境web风险请求监控' -e 'set realname=advai_alert' admin@bj.com -a ${tmp}.gz
