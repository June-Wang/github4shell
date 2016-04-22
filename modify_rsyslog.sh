#!/bin/bash

yum_server='10.54.1.110'
rsyslogd_path='/etc/rsyslog.d'
test -f ${rsyslogd_path}/rsyslog.format.conf ||\
wget http://${yum_server}/shell/rsyslog.format.conf -O ${rsyslogd_path}/rsyslog.format.conf

service rsyslog restart
service rsyslog status
