#!/bin/bash

help () {
        local command=`basename $0`
        echo "/bin/bash ${command} -s <service name> -p <port>
/bin/bash ${command} -s tomcat_agent -p 8080" 1>&2
        exit 1
}

while getopts s:p: opt
do
        case "$opt" in
        s)
                serv_name=$OPTARG
                app_path="/opt/${serv_name}/bin"
                test -d ${app_path} ||\
                eval "echo ${app_path} not found!;exit 1"
                ;;
        p)
                serv_port=$OPTARG
                netstat -nlt 2>/dev/null|grep -E ":${serv_port} " >/dev/null 2>&1 ||\
                eval "echo port: ${serv_port} not listening!please check!;exit 1"
                ;;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -gt 0 -o -z "${serv_name}" -o -z "${serv_port=}" ] && help

pid=`echo $$`
file_name=`basename $0`
lock_file="/tmp/${file_name}.$$"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${lock_file}"  EXIT

test -f ${lock_file} && stat='run'

if [ "${stat}" = 'run' ];then
        echo "$0 (pid  `cat ${lock_file}`) is running..." 1>&2
        exit 1
else
        echo "${pid}" > ${lock_file}
fi

user_name=`whoami`
serv_pid=`pgrep -u ${user_name} java|\
while read pid
do 
        ps -eo pid,args|\
        grep "$pid"|\
        grep "${serv_name}"|\
        awk '{print $1}'
done`

#debug
#echo "${app_path}"

for i in `seq 3`
do
        curl -Is --connect-timeout 5 -m 10 http://127.0.0.1:${serv_port} >/dev/null &&\
        eval "echo ${serv_name} looks OK!;exit 0"
        sleep 2
done

profile="/home/${user_name}/.profile"
test -f ${profile} && source ${profile}
log_path="/home/${user_name}/logs"
test -d ${log_path} || mkdir -p ${log_path}
err_log="${log_path}/${user_name}.${serv_name}.err"

time_now=`date -d now +"%F %T"`
echo "${time_now} restart ${serv_name}!" >> ${err_log}

kill -9 ${serv_pid}
cd ${app_path} && ./startup.sh && sleep 5s
