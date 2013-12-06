#!/bin/bash

usage () {
	echo "USAGE: $0 [host list:format ip user passwd] [shell]" 1>&2
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
exp_file_name="${path}/exec.exp"

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
timeout=30
log_path="./log/${shell}/${mydate}"

pipefile=/tmp/fifo.$$
mkfifo $pipefile
exec 3<>$pipefile

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${pipefile}"  EXIT

thold=12
seq ${thold} >&3

mkdir -p ${log_path}
#mkdir -p ${info_path}

grep -Ev "^#" ${host_list}|\
while read host user password
do
    read -u 3
	(	
		ssh_stat=`nmap -n -p 22 ${host} -P0|awk '/ssh/{print $2}'`
		log="${log_path}/${host}.log"
		if [ "${ssh_stat}" = 'open' ];then
			./exec.exp "${host}" "${user}" "${password}" "${timeout}" "${shell}" "${path}" >${log} 2>&1
		else
			echo "ssh: connect to host ${host} port 22: Connection refused" >> ${log}
		fi
		echo >&3
	)&
done

wait
exec 3>&-
