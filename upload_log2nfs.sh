#!/bin/bash

dst_path='/log_bak/trcbak'

find /production/vasadm/trc/ -mtime +90 -type f -name "*.trc"|head -n 5000|\
while read log_file
do
        date_time=`stat --format="%y" ${log_file}|xargs -r -i date -d "{}" +"%Y/%m/%d"|head -n1`
        test -z "${date_time}" && continue
        path="${dst_path}/${date_time}"
        test -d ${path} || mkdir -p ${path}
        gzip ${log_file} && mv ${log_file}.gz ${path}/
done
