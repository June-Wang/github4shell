#!/bin/bash

id sa ||\
useradd sa
usermod -G wheel sa

ssh_profile='/etc/ssh/sshd_config'
sed -i '/PermitRootLogin/d' ${ssh_profile} && echo 'PermitRootLogin no' >> ${ssh_profile}

pam_su_profile='/etc/pam.d/su'
sed -i -r 's/^#(auth.+required.+pam_wheel.so.*)/\1/' ${pam_su_profile}
