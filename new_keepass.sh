#!/bin/bash

list="$1"
test -f $list ||\
eval "echo $list not exist!;exit 1"

echo '?"Account","Login Name","Password","Web Site","Comments"'
cat $list |\
while read ip user pwd
do
    sed "s|IP_RE|${ip}|;s|USER_RE|${user}|;s|PASSWD_RE|${pwd}|" template.csv
done
