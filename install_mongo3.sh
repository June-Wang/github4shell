#!/bin/bash

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
sudo echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl enable mongod.service

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

sudo sed -i '/exit 0/d' /etc/rc.local
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> /etc/rc.local

test -f /etc/mongod.conf &&\
cp /etc/mongod.conf /etc/mongod.conf.$$ &&\
sed -r -i 's/bindIp:.*$/bindIp: 0.0.0.0/g' /etc/mongod.conf

grep 'mongo_cluster' /etc/mongod.conf >/dev/null 2>&1 ||\
echo '#mongo_cluster
replication:
  replSetName: rs0' >> /etc/mongod.conf
