#!/bin/bash

id=`ifconfig eth0|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -v '255'|head -n 1`

test -z "${id}" &&\
eval "echo eth0 not found!;exit 1"

test -f /etc/salt/minion || exit 1

#grep -E '^master' /etc/salt/minion >/dev/null 2>&1 && \
#sed -r -i 's|master.*|master: salt.lefu.local|' /etc/salt/minion || \
echo "master: salt.lefu.local
id: ${id}" > /etc/salt/minion 

/etc/init.d/salt-minion restart
