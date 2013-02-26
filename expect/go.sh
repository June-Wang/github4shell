#!/bin/bash

usage () {
	echo "USAGE: $0 [host list:format ip user passwd] [shell script]" 1>&2
	exit 1
}

sc_file_name=`basename $0`

[ "$#" -ne 2 ] && usage "${sc_file_name}"

host_list=$1

if [ ! -f "${host_list}" ];then
	echo "${host_list} not exist!"	1>&2
	exit 1
fi

shell=$2

if [ ! -s "./${shell}.sh" ]; then
    echo "${shell}.sh does not exist! " 1>&2
    exit 1
fi

path=`dirname "$0"`
exp_file_name="${path}/conn.exp"

if [ ! -f "${exp_file_name}" ];then
	echo "${exp_file_name} not exist!" 1>&2
	exit 1
else
	chmod +x ${exp_file_name}
fi

if [ -d "${path}" ]; then
    cd ${path}
else
        path='.'
fi

#chk mkpasswd
which mkpasswd >/dev/null 2>&1 || chk='fail'

if [ "${chk}" = 'fail' ];then
	echo "mkpasswd not find! please install expect!" 1>&2
	exit 1
fi

mydate=`date -d  "NOW" +"%Y/%m/%d"`
timeout=15
log_path="./log/${shell}/${mydate}"
info_path="./info/${shell}"

pipefile=/tmp/fifo.$$
mkfifo $pipefile
exec 3<>$pipefile

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${pipefile}"  EXIT

Threshold=12
seq ${Threshold} >&3

mkdir -p ${log_path}
mkdir -p ${info_path}

grep -Ev "^#" ${host_list}|\
while read host user password
do
    read -u 3
	(
		ssh_stat=`nmap -n -p 22 ${host}|awk '/ssh/{print $2}'`
                if [ "${ssh_stat}" = 'open' ];then
			./conn.exp "${host}" "${user}" "${password}" "${timeout}" "${shell}" "${path}" >${log_path}/${host}.log 2>&1
		else
                        echo "ssh: connect to host ${host} port 22: Connection refused" > ${log_path}/${host}.log
                fi
		echo >&3
	)&
done

wait
exec 3>&-
