#!/bin/bash

mk_dir='/etc/check_mk'
test -d ${mk_dir} ||\
mkdir -p ${mk_dir}

test -f ${mk_dir}/mysql.cfg ||\
echo '[client]
user=monitor
password=monitor2015' > ${mk_dir}/mysql.cfg

mk_plugins_dir='/usr/lib/check_mk_agent/plugins'
test -f ${mk_plugins_dir}/mk_mysql ||\
wget https://raw.githubusercontent.com/June-Wang/github4python/master/mk/mk_mysql -O ${mk_plugins_dir}/mk_mysql

test -f ${mk_plugins_dir}/mk_mysql &&\
chmod +x ${mk_plugins_dir}/mk_mysql
