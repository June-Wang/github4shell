#!/bin/bash

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

ps -eo pid|sed '1d'|\
while read pid
do
        test -f /proc/${pid}/smaps || continue
        swap=`sudo awk '/^Swap:/ {SWAP+=$2}END{print SWAP}' /proc/${pid}/smaps`
        test -z "${swap}" && continue
        [ ${swap} -gt 0 ] || continue
        echo -en "$pid\t$swap\n"
done|sort -nrk2|\
while read pid swap
do
        pname=`ps -eo pid,args|awk -v id="$pid" '$1 == id{$1="";print}'|sed 's/^[ ]+//'|grep -oP '^.{1,140}'|head -n1`
        swap=`human_read "${swap}"`
        echo -en "${pid}\t${swap}\t${pname}\n"
done|sed '1i\pid\tswap\tcommand'
