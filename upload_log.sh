#!/bin/bash

local_ip='ip'
log_server='ip'
log_user='root'

#check ssh
ssh_num=`netstat -nt|grep "${log_server}:22"|wc -l`
[ "${ssh_num}" == '0' ] || exit 1

src_path='/home/posp/trc'
dest_path="/app/backup/${local_ip}/trc"

mydate=`date -d "now" +"%Y-%m-%d %H:%M:%S"`

#check src_path
if [ ! -d "${src_path}" ];then
        (echo -en "${mydate}\t"
        logger -i -s "${src_path} not exist!Please check path: ${src_path}" -t upload_trc_log) 1>&2
        exit 1
fi

#check log server status
nmap ${log_server} -n -p22 -P0 | grep 'open' >/dev/null || ssh_status='fail'

if [ "${ssh_status}" = "fail" ];then
        (echo -en "${mydate}\t"
        logger -i -s "Log server can not connect! Please check ${log_server}." -t upload_trc_log) 1>&2
        exit 1
fi

pipefile=/tmp/fifo.$$
mkfifo $pipefile
exec 3<>$pipefile

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${pipefile}"  EXIT

Threshold=10
seq ${Threshold} >&3

hour=`date -d "now" +"%H"`
day=`date -d "now" +"%d"`
yesterday=`date -d "-1 day" +"%d"`
clock=`echo "${hour}/1"|bc`

if [ ${clock} -lt 15 ];then
        find_path="${src_path}/${day}/ ${src_path}/${yesterday}/"
else
        find_path="${src_path}/${day}/"
fi

#ssh  "${log_user}@${log_server}" "test -d ${dest_path} || mkdir -p ${dest_path};exit"
find ${find_path} -type f -name "*.trc*" -perm 664 -mmin +0 -a -mmin -902 -a ! -name "*.gz"|\
while read file
do
        read -u 3
        (
        file_name=`basename ${file}`
        m_time=`stat --format="%y" ${file}`
        file_day=`date -d "${m_time}" +"%Y/%m/%d"`
        dest_path="${dest_path}/${file_day}"
        dest_file="${dest_path}/${file_name}.gz"
        gzip -c "${file}" | ssh  "${log_user}@${log_server}" "test -d ${dest_path} || mkdir -p ${dest_path};cat > ${dest_file};touch -m --date='${m_time}' ${dest_file};exit"
        chmod 644 ${file}
        echo >&3
        )&
done

wait
exec 3>&-

find ${src_path}/ -type f -name "*.trc*" -mtime +7|xargs -r -i rm -f "{}"
