#!/bin/bash

yum_server='10.54.1.112'

wget_cmd="wget http://${yum_server}/shell/output_tripwire.sh"
eval ${wget_cmd} -O /sbin/output_tripwire.sh ||\
eval "echo ${wget_cmd} fail!;exit 1" &&\
chmod +x /sbin/output_tripwire.sh

grep 'output_tripwire.sh' /etc/crontab >/dev/null 2>&1 || echo "0 3 * * * root /sbin/output_tripwire.sh >/dev/null" >>/etc/crontab
