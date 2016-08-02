#!/bin/bash

#id=`ifconfig -a|grep -A1 eth|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -v '255'|head -n 1`
id=`ip address show|awk '/inet/{print $2}'|grep -oP '^.+\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127'|head -n1`

test -z "${id}" &&\
eval "echo eth0 not found!;exit 1"

test -f /etc/salt/minion || exit 1

#grep 'salt.master.local' /etc/hosts >/dev/null 2>&1 &&\
#echo '10.54.1.110 salt.master.local' >> /etc/hosts

#grep -E '^master' /etc/salt/minion >/dev/null 2>&1 && \
#sed -r -i 's|master.*|master: salt.lefu.local|' /etc/salt/minion || \
echo "master: salt.master.local
id: ${id}" > /etc/salt/minion 

service salt-minion restart
