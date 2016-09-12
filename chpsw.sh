#!/bin/bash

ip=`/sbin/ip address show|awk '/inet/{print $2}'|grep -oP '^.+\d{1,3}(\.\d{1,3}){3}'|grep 10.211|head -n1`

output_file="/tmp/pswd.file.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${output_file} && rm -f ${output_file}"  EXIT

grep 'bash' /etc/passwd |awk -F':' '{print $1}'|\
while read user_id
do
        passwd=`openssl rand -base64 11|grep -oE '^.{15}'|head -n 1`
        #echo ${user_id}:${passwd}|/usr/sbin/chpasswd
        echo -en "${ip} ${user_id} ${passwd}\n" >> ${output_file}
done

test -f ${output_file} && cat ${output_file}
