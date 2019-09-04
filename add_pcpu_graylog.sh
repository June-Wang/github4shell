#!/bin/bash

graylog_server='127.0.0.1'
url='https://raw.githubusercontent.com/June-Wang/github4shell/master/pcpu_graylog.sh'
path='/usr/local/bin'
file=`echo ${url}|awk -F'/' '{print $NF}'`

#echo ${file}
#exit
test -f ${path}/${file} && exit 0

test -d ${path} &&\
wget ${url} -O ${path}/${file} &&\
test -f ${path}/${file} && chmod +x ${path}/${file} && ls -lth ${path}/${file}

grep "${file}" /etc/crontab >/dev/null 2>&1 ||\
echo "* * * * * root ${path}/${file} eth0 ${graylog_server} >/dev/null 2>&1" >> /etc/crontab
