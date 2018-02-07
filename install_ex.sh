#!/bin/bash

YUM_SERVER='yum.server.local'

test -f /usr/bin/yum && \
yum --skip-broken --nogpgcheck install -y htop salt-minion mawk koan check-mk-agent  
test -f /usr/bin/yum && yum --skip-broken --nogpgcheck update -y

cmds=(
ali_mirrors.sh
install_nrpe_xinetd.sh
install_tripwire.sh
add_tripwire.sh
update_sshd.sh
)

for shell in "${cmds[@]}"
do
        curl http://${YUM_SERVER}/shell/${shell}|/bin/bash
done

echo "koan -r --server=${YUM_SERVER} --profile=CentOS6.8-Base-x86_64" > /root/koan.sh
