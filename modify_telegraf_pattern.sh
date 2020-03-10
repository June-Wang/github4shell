#!/bin/bash

pattern=`awk -F':' 'BEGIN{ORS="|"}{print $1}' /etc/passwd|sed 's/.$//;s/-/|/g'`

telegraf_config='/etc/telegraf/telegraf.conf'
test -f ${telegraf_config} &&\
echo "${pattern}"|xargs -r -i sed -r -i 's/pattern = .*$/pattern = \"{}\"/g' ${telegraf_config}
