#!/bin/bash

backup_list='/usr/shell/backup.list'
test -f ${backup_list}||\
eval "echo ${backup_list} not found!;exit 1"

cat ${backup_list}|\
while read src_path dst_path
do
        test -d "${src_path}" || eval "echo ${src_path} not found!;continue"
        find ${src_path} -mtime +30 -type f|\
        while read log_file
        do
                echo "${log_file}"|grep 'logstash' >/dev/null 2>&1 && rm -f "${log_file}"
                date_time=`stat --format="%y" ${log_file}|xargs -r -i date -d "{}" +"%Y/%m/"|head -n1`
                test -z "${date_time}" && continue
                path="${dst_path}/${date_time}"
                test -d ${path} || mkdir -p ${path}
                gzip ${log_file} && mv ${log_file}.gz ${path}/ || mv ${log_file} ${path}/
        done
done
