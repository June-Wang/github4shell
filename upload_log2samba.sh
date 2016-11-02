#!/bin/bash

ip=`ip addr show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127\.|255'|head -n1`
dst_path='/backup/log'

find /opt/jfsc/ -type d -name 'logs'|grep -v Catalina|\
while read path
do
    name=`echo ${path}|awk -F'/' '{print $(NF-1)}'`
    #echo "$path ${name}"
    dst="${dst_path}/${ip}/${name}"
    test -d ${dst} || mkdir -p ${dst}
    find ${path} -type f -mtime +15 |grep logs|head -n5000|\
    while read log_file
    do
        date_time=`stat --format="%y" ${log_file}|xargs -r -i date -d "{}" +"%Y/%m/%d"|head -n1`
        test -z "${date_time}" && continue
        backup_path="${dst}/${date_time}"
        test -d ${backup_path} || mkdir -p ${backup_path}
        gzip ${log_file} && mv ${log_file}.gz ${backup_path}/
    done
done
