#!/bin/bash

cmds=(
mirrors_local.sh
init_debian.sh
)


for shell in "${cmds[@]}"
do
    curl http://yum.suixingpay.local/shell/${shell}|/bin/bash -x
done

#wget http://yum.suixingpay.local/shell/binding_bond.sh -O /root/binding_bond.sh
