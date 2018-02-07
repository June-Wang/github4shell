#!/bin/bash

YUM_SERVER='yum.server.local'

echo -en '设置vim别名'
echo -en '\t->\t'
echo "alias vi='vim'"  > /etc/profile.d/vim_alias.sh

grep -E '^set ts=4' /etc/vimrc >/dev/null 2>&1 ||\
echo "set nocompatible
set ts=4
set backspace=indent,eol,start
syntax on" >> /etc/vimrc
echo 'ok'

test -f /usr/bin/yum && \
yum --skip-broken --nogpgcheck install -y htop salt-minion mawk 
test -f /usr/bin/yum && yum --skip-broken --nogpgcheck update -y

#stop postfix
chkconfig postfix off
service postfix stop

cmds=(
ali_mirrors.sh
install_tripwire.sh
add_tripwire.sh
update_sshd.sh
)

for shell in "${cmds[@]}"
do
        curl http://${YUM_SERVER}/shell/${shell}|/bin/bash
done
