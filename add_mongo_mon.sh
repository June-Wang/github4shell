#!/bin/bash

path='/usr/local/nagios-plugins'
test -d "${path}" || mkdir -p ${path}
wget https://github.com/mzupan/nagios-plugin-mongodb/raw/master/check_mongodb.py -O ${path}/check_mongodb.py
test -f ${path}/check_mongodb.py && chmod +x ${path}/check_mongodb.py

test -f /usr/bin/pip2 ||\
sudo apt install python-pip -y

test -f /usr/bin/pip2 ||\
eval "echo pip2 not found!;exit 1"

pip2 install pymongo

test -d /etc/nagios/nrpe.d &&\
echo 'command[check_mongo_service_local]=/usr/local/nagios-plugins/check_mongodb.py -u root -p 'MongoPSW' -D -H 127.0.0.1 -A connect -P 27018
command[check_mongo_memory_usage]=/usr/local/nagios-plugins/check_mongodb.py -u root -p 'MongoPSW' -D -H 127.0.0.1 -A memory -P 27018 -W 90 -C 95 
command[check_mongo_connections]=/usr/local/nagios-plugins/check_mongodb.py -u root -p 'MongoPSW' -D -H 127.0.0.1 -A connections -P 27018' > /etc/nagios/nrpe.d/check_mongo.cfg

test -f /usr/local/nagios-plugins/check_mongodb.py &&\
ls -lth /usr/local/nagios-plugins/check_mongodb.py
#/usr/local/nagios-plugins/check_mongodb.py -D -H 127.0.0.1 -A connect -P 27017

#!/bin/bash

/sbin/ip addr list|\
grep -oP '\d{1,3}(\.\d{1,3}){3}'|\
grep -Ev '^127|255$'|head -n1|xargs -r -i sed -r -i 's|127.0.0.1|{}|' /etc/nagios/nrpe.d/check_mongo.cfg
