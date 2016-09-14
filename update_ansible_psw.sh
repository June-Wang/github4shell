#!/bin/bash

salt '*' cmd.run 'curl http://yum.server.local/shell/chpsw_ansible.sh|/bin/bash' |\
grep -P '\d{1,3}(\.\d{1,3}){3}'|\
awk '$NF>2{print}'|sed -r 's/^[ ]+//'|\
sort
