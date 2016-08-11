#!/bin/bash

report_path='/var/lib/tripwire/report/'
report_date=`date -d "-1day" +"%Y%m%d"`
output_path="/var/log/tripwire/report/"

host_name=`hostname`
ip=`ip address show|awk '/inet/{print $2}'|grep -oP '^.+\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127'|head -n1`

file_name="${ip}-${host_name}-${report_date}"
output_file="${output_path}/${file_name}.txt"

test -d ${output_path} || mkdir -p ${output_path}

find ${report_path} -type f -name "*.twr"|grep "${report_date}"|\
xargs -r -i twprint --print-report --twrfile "{}" >> ${output_file}

test -f "${output_file}" && gzip "${output_file}" && chmod 0600 "${output_file}.gz"
