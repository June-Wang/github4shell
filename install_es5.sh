#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update && sudo apt-get install elasticsearch

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
fs.file-max=655360' >> /etc/sysctl.conf

sudo /sbin/sysctl -p 

test -f /etc/elasticsearch/elasticsearch.yml &&\
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.$$ &&\
echo 'cluster.name: graylog
node.name: localhost
network.host: 0.0.0.0
#集群中的主机
discovery.zen.ping.unicast.hosts: ["infra-sg-guardian-graylog1:9300","infra-sg-guardian-graylog2:9300","infra-sg-guardian-graylog3:9300","infra-sg-guardian-graylog4:9300","infra-sg-guardian-graylog-proxy:9300"]
#可发现的主节点node/2+1算出
discovery.zen.minimum_master_nodes: 2
node.master: false
node.data: true
bootstrap.system_call_filter: false
http.cors.enabled: true
http.cors.allow-origin: "*"' > /etc/elasticsearch/elasticsearch.yml

sudo apt-get install -y apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen
