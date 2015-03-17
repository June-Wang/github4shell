#!/bin/bash

list="$1"
test -f $list ||\
eval "echo $list not exist!;exit 1"

echo '?"Account","Login Name","Password","Web Site","Comments"'
cat $list |\
while read ip user pwd
do
        grep "$ip\"" lefu-HLG.kdb.csv >/dev/null 2>&1 && host='1' ||host='0'
        if [ "${host}" == '1' ];then
                grep "$ip\"" lefu-HLG.kdb.csv|sed -r 's|".[^"]*"|"'${pwd}'"|3'
        else
                echo "\"${ip}\",\"$user\",\"$pwd\",\"\",\"\""
        fi
done
