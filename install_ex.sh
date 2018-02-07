#!/bin/bash

YUM_SERVER='yum.server.local'

test -f /usr/bin/yum && \
yum --skip-broken --nogpgcheck install -y bc htop salt-minion mawk koan check-mk-agent  
test -f /usr/bin/yum && yum --skip-broken --nogpgcheck update -y

cmds=(
ali_mirrors.sh
install_nrpe_xinetd.sh
install_tripwire.sh
add_tripwire.sh
)

for shell in "${cmds[@]}"
do
        curl http://${YUM_SERVER}/shell/${shell}|/bin/bash
done

echo "koan -r --server=${YUM_SERVER} --profile=CentOS6.8-Base-x86_64" > /root/koan.sh

yum_releasever=`rpm -qf /etc/redhat-release|head -n1|xargs -r -i rpm -q --qf %{version} '{}'|sed 's/Server//'`

[ `echo "${yum_releasever} < 7"|bc` -eq 1 ] &&\
curl http://${YUM_SERVER}/shell/update_sshd.sh|/bin/bash ||\
exit 0
