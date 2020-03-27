#!/bin/bash

ip="$1"

hostname=`hostname`

mtr='mtr --no-dns -4 --report'
fields='ip loss   snt   last   avg  best  wrst stdev'

timetamp=`date -d now +"%s%N"`

$mtr ${ip} |grep -v '???'|grep -Ev 'Start|Loss'|\
awk '{$1="";print}'|\
while read ${fields}
do
    echo "mtr,hostname=${hostname},ip=${ip} loss=${loss},snt=${snt},last=${last},avg=${avg},best=${best},wrst=${wrst},stdev=${stdev} ${timetamp}"
done|sed 's/%//g'
