#!/bin/bash

nginx_log_path='/usr/local/nginx/logs'
nginx_pid="${nginx_log_path}/nginx.pid"

if [ ! -d "${nginx_log_path}" ];then
        echo "${nginx_log_path} not exist!" 1>&2
        exit 1
else
        find ${nginx_log_path} -type f -size 0|xargs -r -i rm -f "{}"
fi

if [ ! -f "${nginx_pid}" ];then
        echo "${nginx_pid} not exist!" 1>&2
        exit 1
fi

path_suffix=`date -d "-1 day" +"%Y/%m"`
backup_path="${nginx_log_path}/${path_suffix}"

test -d "${backup_path}" || mkdir -p "${backup_path}"

file_suffix=`date -d "-1 day" +"%F"`
find ${nginx_log_path}/ -mindepth 1 -maxdepth 1 -type f -name '*.log'|\
while read log
do
	file=`basename ${log}`
	mv ${nginx_log_path}/${file} ${backup_path}/${file}.${file_suffix}
done

kill -USR1 `cat ${nginx_pid}` && exit 0 ||\
eval "echo nginx logrotate fail!;exit 1"

#echo '0 0 * * * root /etc/nginx/nginx_logrotate.sh >/dev/null' >> /etc/crontab
