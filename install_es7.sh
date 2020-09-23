#!/bin/bash

#set ulimited
test -f /etc/security/limits.d/100-app.conf ||\
echo '* soft nproc 10240
* hard nproc 10240
* soft nofile 65535
* hard nofile 65535' > /etc/security/limits.d/100-app.conf

#set sysctl
grep 'vm.max_map_count' /etc/sysctl.conf >/dev/null 2>&1 ||\
echo 'vm.max_map_count=655360
fs.file-max=655360
vm.max_map_count=262144
vm.swappiness = 0' >> /etc/sysctl.conf
sysctl -p

/usr/share/elasticsearch/bin/elasticsearch-certutil ca
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12

chgrp elasticsearch /usr/share/elasticsearch/elastic-certificates.p12 /usr/share/elasticsearch/elastic-stack-ca.p12
chmod 640 /usr/share/elasticsearch/elastic-certificates.p12 /usr/share/elasticsearch/elastic-stack-ca.p12

test -f /usr/share/elasticsearch/elastic-certificates.p12 &&\
cp /usr/share/elasticsearch/elastic-certificates.p12 /etc/elasticsearch/

test -f /usr/share/elasticsearch/elastic-stack-ca.p12 &&\
cp /usr/share/elasticsearch/elastic-stack-ca.p12 /etc/elasticsearch/

es_config='/etc/elasticsearch/elasticsearch.yml'

my_date=`date -d now +"%F.$$"`
test -f ${es_config} &&\
cp ${es_config} ${es_config}.${my_date}

hostname=`hostname`
echo 'cluster.name: es-cluster
node.name: node01
network.host: 0.0.0.0
node.master: true
node.data: true
node.ingest: false
transport.tcp.port: 9300
http.port: 9200
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization
path.data: /data/elasticsearch
path.logs: /var/log/elasticsearch
discovery.seed_hosts: ["192.168.100.128:9300","192.168.100.130:9300","192.168.100.131:9300"]  # 集群恢复时，发现那些主机可接受请求
cluster.initial_master_nodes: ["node01","node02","node03"] # 手动指定可以成为 mater 的所有节点的 name 或者 ip，这些配置将会在第一次选举中进行计算
# enable Security feature
xpack.security.enabled: true
# add to the end
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/elastic-certificates.p12
gateway.recover_after_nodes: 2
gateway.expected_nodes: 2
gateway.recover_after_time: 5m' > ${es_config}
test -f ${es_config} && sed -r -i "s/${hostname}/HOSTNAME/g" ${es_config}
cp ${es_config} ${es_config}.cluster

echo 'cluster.name: es-cluster
node.name: localhost
network.host: 0.0.0.0
node.master: true
node.data: true
http.cors.enabled: true
http.cors.allow-origin: "*"
path.data: /data/elasticsearch
path.logs: /var/log/elasticsearch
discovery.type: single-node
# enable Security feature
xpack.security.enabled: true
# add to the end
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/elastic-certificates.p12' > ${es_config}.single

mkdir -p /data/elasticsearch/ && sudo chown -R elasticsearch.elasticsearch /data/elasticsearch/
es_default_config='/etc/default/elasticsearch'
chown elasticsearch.elasticsearch -R /usr/share/elasticsearch/bin/ /etc/elasticsearch/

#test -f ${es_default_config} &&\
#chown elasticsearch.elasticsearch ${es_default_config}
#grep -E '^ES_PATH_CONF' ${es_default_config} >/dev/null 2>&1 ||\
#echo 'ES_PATH_CONF=/etc/elasticsearch' >> ${es_default_config}

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

grep 'enable Security feature' ${es_config} >/dev/null 2>&1 ||\
echo '# enable Security feature
xpack.security.enabled: true
# add to the end
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/elastic-certificates.p12' >> ${es_config}

echo '/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -u "http://127.0.0.1:9200" '
echo 'curl -u elastic:passwd -XGET "http://127.0.0.1:9200/_cluster/health?pretty"'

systemctl daemon-reload
systemctl enable elasticsearch.service
