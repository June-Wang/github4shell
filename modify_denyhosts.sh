#!/bin/bash

denyhosts_conf='/etc/denyhosts.conf'

DATE=`date -d now +"%F_%H-%M-%S"`
test -f ${denyhosts_conf} &&\
sed -r -i.bak${DATE} 's/^PURGE_DENY.*$/PURGE_DENY = 5m/;
s/^DENY_THRESHOLD_ROOT.+$/DENY_THRESHOLD_ROOT = 3/;
s/^HOSTNAME_LOOKUP.+$/HOSTNAME_LOOKUP=NO/;' ${denyhosts_conf}
