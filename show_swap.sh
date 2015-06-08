#!/bin/bash

user=`whoami`
id=`id ${user} -u`

if [ "${id}" != '0' ];then
	echo "Sorry!You must be root to run this script!" 1>&2
	exit 1
fi

printf "%-5s\t%15s\t%20s\n" PID Swap Proc_Name
find /proc/ -maxdepth 2 -name "smaps"|\
while read smaps
do
        test -f ${smaps} || continue
        pid=`echo ${smaps}|awk -F'/' '{pid=$3;print pid}'`
        [ "$pid" = '1' ] && continue
        pname=`ps -eo pid,args|grep "${pid}"|grep -v 'grep'|awk '{$1="";print}'|sed 's/^[ ]+//'`
        swap=`awk '/Swap:/{sum+=$2}END{print sum}' ${smaps}`
        [ "$swap" = '0' -o "$swap" = '' ] && continue
        if [ -n "${pname}" -a -n "${swap}" ];then
                echo -en "$pid\t$swap\t$pname\n"
        fi
done|grep -E '^[1-9]'|sort -nrk2|\
awk -F'\t' '{
    pid[NR]=$1;
    size[NR]=$2;
    name[NR]=$3;
}
END{
    for(id=1;id<=length(pid);id++)
    {
        if(size[id]<1024)
            printf("%-5s\t%15sKB\t%s\n",pid[id],size[id],name[id]);
        else if(size[id]<1048576)
            printf("%-5s\t%15.2fMB\t%s\n",pid[id],size[id]/1024,name[id]);
        else
            printf("%-5s\t%15.2fGB\t%s\n",pid[id],size[id]/1048576,name[id]);
    }
}'
