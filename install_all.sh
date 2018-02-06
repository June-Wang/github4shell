#!/bin/bash

YUM_SERVER='x.x.x.x'

cmds=(
update_sshd.sh
init_redhat.sh
ali_mirrors.sh
add_history.sh
add_sysinfo.sh
)

for shell in "${cmds[@]}"
do
        curl http://${YUM_SERVER}/shell/${shell}|/bin/bash
done

curl http://${YUM_SERVER}/shell/binding_bond.sh > /root/binding_bond.sh
curl http://${YUM_SERVER}/shell/install_ex.sh > /root/install_ex.sh
