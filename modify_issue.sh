#!/bin/bash

id=`ip address show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$|\.0$'|head -n1`

test -f /etc/issue && \
echo -en "IP:\t${id}\n" > /etc/issue
