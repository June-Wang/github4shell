#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/oss-6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt-get update && sudo apt-get install elasticsearch-oss

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

test -f /etc/elasticsearch/log4j2.properties &&\
sed -r -i 's/^logger.action.level.*$/logger.action.level = info/g' /etc/elasticsearch/log4j2.properties

es_config='/etc/default/elasticsearch'
test -f ${es_config} &&\
sed -r -i '/^DATA_DIR=/d' ${es_config} &&\
sudo echo 'DATA_DIR=/data/elasticsearch/' >> ${es_config}
sudo mkdir -p /data/elasticsearch/ && sudo chown -R elasticsearch.elasticsearch /data/elasticsearch/

grep 'vm.max_map_count' /etc/sysctl.conf >/dev/null 2>&1 ||\
echo 'vm.max_map_count=655360
fs.file-max=655360
vm.max_map_count=262144
vm.swappiness = 0' >> /etc/sysctl.conf

sudo /sbin/sysctl -p 

es_config='/etc/elasticsearch/elasticsearch.yml'
test -f ${es_config} &&\
cp ${es_config} ${es_config}.$$ &&\
hostname=`hostname`
echo 'cluster.name: graylog
node.name: HOSTNAME
network.host: 0.0.0.0
#集群中的master
discovery.zen.ping.unicast.hosts: ["GRAYLOG_PERFIX-graylog1:9300","GRAYLOG_PERFIX-graylog2:9300","GRAYLOG_PERFIX-graylog3:9300"]
#可发现的主节点node/2+1算出
discovery.zen.minimum_master_nodes: 2
node.master: true
node.data: true
bootstrap.system_call_filter: false
http.cors.enabled: true
http.cors.allow-origin: "*"
path.data: /data/elasticsearch
path.logs: /var/log/elasticsearch
gateway.recover_after_nodes: 3
gateway.expected_nodes: 3
gateway.recover_after_time: 5m' > ${es_config}
test -f ${es_config} && sed -r -i "s/${hostname}/HOSTNAME/g"

sudo apt-get install -y apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen
