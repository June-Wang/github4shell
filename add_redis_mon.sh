#!/bin/bash

curl -L https://cpanmin.us | perl - --sudo App::cpanminus
/usr/local/bin/cpanm Redis
/usr/local/bin/cpanm Term::ReadKey
/usr/local/bin/cpanm JSON

path='/etc/check_mk'
test -d ${path} || mkdir -p ${path}

grep 'check_redis_version' ${path}/mrpe.cfg >/dev/null 2>&1 ||\
echo 'check_redis_version /usr/local/nagios-plugins/check_redis_version.pl -H r-gs55cb06e68d4d84.redis.singapore.rds.aliyuncs.com -P 6379 -t3' >> ${path}/mrpe.cfg
