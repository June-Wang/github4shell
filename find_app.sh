#!/bin/bash

tmp_file="/tmp/app.info.$$"

ip=`ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

netstat -nlpt|grep java|awk '{print $4}'|awk -F':' '{print $2}' > ${tmp_file}

find /usr/local/ -type f -name '*.sh'|grep star|\
while read file
do
  #echo "$file"
  port=`grep -oP "=\d{4,6}" $file|grep -Ev '#'|head -n1|awk -F'=' '{print $2}'`
  test -n "${port}" && echo -en "${file}\t${port}\n"
done|\
while read file port
do
  #echo -e "$file\t$port"
  app=`echo "$file" |sed -r 's|/usr/local/||;s|springboot/||'|awk -F'/' '{print $1}'`
  grep "$port" ${tmp_file} >/dev/null 2>&1 &&\
  echo -en "$ip,$app,$file,$port\n"
done
