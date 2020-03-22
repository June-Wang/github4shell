#!/bin/bash

sudo service elasticsearch stop
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

es_default_config='/etc/default/elasticsearch'
sudo chown elasticsearch.elasticsearch -R /usr/share/elasticsearch/bin/
sudo chown elasticsearch.elasticsearch ${es_default_config}

grep -E '^ES_PATH_CONF' ${es_default_config} >/dev/null 2>&1 ||\
echo 'ES_PATH_CONF=/etc/elasticsearch' >> ${es_default_config}
sudo apt-get update && sudo apt-get install elasticsearch -y

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

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

#sudo service logstash stop && sudo apt-get install logstash -y
#sudo service logstash start
