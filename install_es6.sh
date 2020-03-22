#!/bin/bash

JAVA_HOME=/data/jdk1.8.0_202

echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt-get update && sudo apt-get install elasticsearch -y
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

test -f /etc/elasticsearch/log4j2.properties &&\
sed -r -i 's/^logger.action.level.*$/logger.action.level = info/g' /etc/elasticsearch/log4j2.properties

es_config='/etc/default/elasticsearch'
test -f ${es_config} &&\
sed -r -i '/^DATA_DIR=/d' ${es_config} &&\
sudo echo 'DATA_DIR=/data/elasticsearch/' >> ${es_config}

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

sudo mkdir -p /data/elasticsearch/ && sudo chown -R elasticsearch.elasticsearch /data/elasticsearch/
es_default_config='/etc/default/elasticsearch'
sudo chown elasticsearch.elasticsearch -R /usr/share/elasticsearch/bin/
sudo chown elasticsearch.elasticsearch ${es_default_config}
grep -E '^ES_PATH_CONF' ${es_default_config} >/dev/null 2>&1 ||\
echo 'ES_PATH_CONF=/etc/elasticsearch' >> ${es_default_config}

mydate=`date -d now +"%F_%H-%M-%S"`
es_config='/etc/elasticsearch/elasticsearch.yml'
test -f ${es_config} && sudo cp ${es_config} ${es_config}.${mydate}

grep -E '^path.data' ${es_config} >/dev/null 2>&1 ||\
echo 'path.data: /data/elasticsearch' >> ${es_config}
grep -E '^path.logs' ${es_config} >/dev/null 2>&1 ||\
echo 'path.logs: /var/log/elasticsearch' >> ${es_config}

grep -E '^gateway.recover_after_nodes' ${es_config} >/dev/null 2>&1 ||\
echo 'gateway.recover_after_nodes: 3' >> ${es_config}
grep -E '^gateway.expected_nodes' ${es_config} >/dev/null 2>&1 ||\
echo 'gateway.expected_nodes: 3' >> ${es_config}
grep -E '^gateway.recover_after_time' ${es_config} >/dev/null 2>&1 ||\
echo 'gateway.recover_after_time: 5m' >> ${es_config}

#sudo apt-get install -y apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen
sudo apt-get install -y apt-transport-https uuid-runtime pwgen
