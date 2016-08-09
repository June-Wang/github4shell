#!/bin/bash

#删除无用的账户
users=(
lp
shutdown
halt
news
uucp
games
operator
gopher
)

for user in "${users[@]}"
do
        grep "${user}" /etc/passwd >/dev/null 2>&1 && \
        userdel ${user}
done

#禁止root直接登陆
ssh_profile='/etc/ssh/sshd_config'
sed -i '/PermitRootLogin/d' ${ssh_profile} && echo 'PermitRootLogin no' >> ${ssh_profile}

#非wheel组用户不能su到root用户下
pam_su_profile='/etc/pam.d/su'
sed -i -r 's/^#(auth.+required.+pam_wheel.so.*)/\1/' ${pam_su_profile}

#设置口令长度
#PASS_MAX_DAYS       99999
#PASS_MIN_DAYS       0
#PASS_MIN_LEN        5
#PASS_WARN_AGE       7

test -f /etc/login.defs &&\
sed -r -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/;
s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 0/;
s/^PASS_MIN_LEN.*/PASS_MIN_LEN 8/;
s/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
