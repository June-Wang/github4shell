#!/bin/bash

users=`ps -eo user|sort -u|grep -v 'USER'|awk 'BEGIN{ORS="|"}{print $1}'|sed -r 's/.$//'`
#echo ${users}
#exit 

config='/etc/telegraf/telegraf.conf'
test -f ${config} &&\
echo "${users}"|xargs -r -i sed -r -i 's/pattern =.*/pattern = "{}"/' ${config} &&\
sed -r -i 's/user =(.*)/#user =\1/' ${config}
service telegraf restart
