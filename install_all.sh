#!/bin/bash

YUM_SERVER='xxx.xxx.xxx.xxx'

cmds=(
init_redhat.sh
ali_mirrors.sh
add_history.sh
add_sysinfo.sh
install_tripwire.sh
add_tripwire.sh
)

for shell in "${cmds[@]}"
do
        curl http://${YUM_SERVER}/shell/${shell}|/bin/bash
        echo "${shell}" |grep 'ali_mirrors' >/dev/null 2>&1 &&\
        yum --skip-broken --nogpgcheck install -y wget
done

ls /usr/bin/yum >/dev/null 2>&1 && \
yum --skip-broken --nogpgcheck install -y \
lrzsz check-mk-agent htop salt-minion mawk vim

#salt
curl http://${YUM_SERVER}/shell/modify_salt.sh|/bin/bash
