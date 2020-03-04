#!/bin/bash

test -f /etc/check_mk/mrpe.cfg || mkdir -p /etc/check_mk/

echo 'check_rabbitmq_healthchecks_mq /usr/local/nagios-plugins/check_rabbitmq_healthchecks.py  -H 172.21.194.24 -u admin -p advance.ai2016 -t 3
check_rabbitmq_healthchecks_mq2 /usr/local/nagios-plugins/check_rabbitmq_healthchecks.py  -H 172.21.194.130 -u admin -p advance.ai2016 -t 3' >> /etc/check_mk/mrpe.cfg
