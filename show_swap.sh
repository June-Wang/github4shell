#!/bin/bash

which bc >/dev/null ||\
eval "echo bc not found!;exit 1" 

user=`whoami`
uid=`id ${user} -u`

if [ "${uid}" != '0' ];then
        echo "Sorry!You must be root to run this script!" 1>&2
        exit 1
fi

human_read () {
local number="$1"
if [ `echo "(${number}-1073741824) > 0"|bc` -eq 1 ];then
        output="`echo "scale=2;${number}/1024/1024/1024"|bc`T"
elif [ `echo "(${number}-1048576) > 0"|bc` -eq 1 ];then
        output="`echo "scale=2;${number}/1024/1024"|bc`G"
elif [ `echo "(${number}-1024) > 0"|bc` -eq 1 ];then
        output="`echo "scale=2;${number}/1024"|bc`M"
else
        output="${number}K"
fi
echo "${output}"
}

echo -en "PID\tSwap\tProc_Name\n"
ps -eo pid|sed '1d'|\
while read pid
do
        smaps="/proc/${pid}/smaps"
        test -f ${smaps} || continue
        test -s ${smaps} && continue
        pname=`ps -eo pid,args|awk -v id="$pid" '$1 == id{$1="";print}'|sed 's/^[ ]+//'`
        swap=`awk '/Swap:/{sum+=$2}END{print sum}' ${smaps}`
        test -z "${swap}" && continue
        if [ "$swap" != '0' -a ${pid} -gt 1 ];then
                echo -en "$pid\t$swap\t$pname\n"
        fi
done|grep -E '^[1-9]'|sort -nrk2|\
while read pid swap pname
do
        swap=`human_read "${swap}"`
        echo -en "${pid}\t${swap}\t${pname}\n"
done
