#!/bin/bash

export LANG=en_US.UTF-8

list="$1"
test -f "${list}" ||\
eval "echo ${list} not found!;exit 1"

url_date=`date -d now +"%Y%m%d"`
file_date=`date -d -1day +"%Y%m%d"`
file_server='mysql.server.local'

tmp_path="/tmp/send_mysql_slow_log_$$/"
test -d ${tmp_path} || mkdir -p ${tmp_path}

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${tmp_path} && rm -rf ${tmp_path}"  EXIT

url="http://${file_server}/${url_date}/"
curl -s "${url}"|grep -oP '".+?"'|grep "${file_date}"|\
sed 's/"//g'|\
while read file
do
    curl -s "${url}${file}" > ${tmp_path}/${file} ||\
    cat /dev/null > ${tmp_path}/${file}
done

cat ${list}|grep -Ev '^#|^$'|\
while read host user_list
do
    file_name=`ls ${tmp_path}/|grep "${host}"|head -n1`
    test -z "${file_name}" && continue
    subj=`echo ${file_name}|awk -F'/' '{print $NF}'`
    file="${tmp_path}${file_name}"
    test -n "${file}" && cat ${file} |head -n200|mutt -s ${subj} -e 'set realname=report' -e 'set from="sysop@ab.com"' ${user_list} -a ${file}
    sleep 44s
done

#list
#ip mail1,mail2
