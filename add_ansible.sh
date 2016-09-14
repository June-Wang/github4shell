#!/bin/bash

user_id='ansible'

id ${user_id} >/dev/null 2>&1 || useradd -m -s /bin/bash ${user_id}
usermod -G wheel ${user_id}

test -f /etc/sudoers ||\
eval "echo sudo not install!;exit 1"

grep "${user_id}" /etc/sudoers  >/dev/null 2>&1 ||\
echo "
${user_id} ALL=(ALL) NOPASSWD: ALL
Defaults:${user_id} !requiretty" >> /etc/sudoers
