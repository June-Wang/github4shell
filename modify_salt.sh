#!/bin/bash

master_ip='10.54.1.110'
id=`ifconfig -a|grep -E -A1 'eth0|bond0'|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127\.|255'`

test -z "${id}" &&\
eval "echo eth0 not found!;exit 1"

test -f /etc/salt/minion || exit 1

#grep -E '^master' /etc/salt/minion >/dev/null 2>&1 && \
#sed -r -i 's|master.*|master: salt.lefu.local|' /etc/salt/minion || \
echo "master: salt.lefu.local
id: ${id}" > /etc/salt/minion 

grep 'salt.lefu.local' /etc/hosts ||\
echo '10.54.1.110 salt.lefu.local' >> /etc/hosts

service salt-minion restart
