#!/bin/bash

test -f /etc/login.defs && \
sed -r -i 's/^PASS_MAX_DAYS.+$/PASS_MAX_DAYS    99999/g;s/^PASS_MIN_DAYS.+$/PASS_MIN_DAYS    0/g;s/^PASS_MIN_LEN.+$/PASS_MIN_LEN    8/g' /etc/login.defs

grep 'bash' /etc/passwd|awk -F':' '{print $1}'|\
while read user
do
        id ${user} && chage -M 99999 ${user}
done
