#!/bin/bash

YUM_SERVER='yum.server.local'

ls /usr/bin/yum >/dev/null 2>&1 && \
yum --skip-broken --nogpgcheck install -y \
htop salt-minion mawk 

cmds=(
install_tripwire.sh
add_tripwire.sh
id.sh
)

for shell in "${cmds[@]}"
do
        curl http://${YUM_SERVER}/shell/${shell}|/bin/bash
done

#yum --skip-broken --nogpgcheck update -y
