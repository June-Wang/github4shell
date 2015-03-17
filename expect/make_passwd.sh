#!/bin/bash

host_list="$1"
USER="$2"

pipefile=/tmp/fifo.$$
mkfifo $pipefile
exec 3<>$pipefile

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${pipefile}"  EXIT

thold=5
seq ${thold} >&3

shell_name=`echo $0|awk -F'/' '{print $(NF)}'`
#echo $shell_name
#exit 

log_path="./logs/${shell_name}"
test -d ${log_path} || mkdir -p ${log_path}

#echo -en "\n"
grep -Ev "^#" ${host_list}|\
while read host user password
do
    read -u 3
        (
                passwd=`openssl rand -base64 11|grep -oE '^.{10}'|head -n 1`
                echo -en "${host}\t${user}\t${passwd}\n" >> ${host_list}.new.passwd
                sshpass -p "${password}" ssh -o StrictHostKeyChecking=no -n $user@$host "echo ${USER}:${passwd}|chpasswd" > ${log_path}/${host}.log 2>&1
                echo >&3
        )&
done

wait
exec 3>&-
