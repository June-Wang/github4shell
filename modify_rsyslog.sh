#!/bin/bash

yum_server='yum.server.local'
rsyslogd_path='/etc/rsyslog.d'
test -f ${rsyslogd_path}/rsyslog.format.conf ||\
wget http://${yum_server}/shell/rsyslog.format.conf -O ${rsyslogd_path}/rsyslog.format.conf

service rsyslog restart
service rsyslog status
