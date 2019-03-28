#!/bin/bash

tmp_deb='/tmp/graylog-2.5-repository_latest.deb'
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_deb} && rm -f ${tmp_deb}" EXIT

wget https://packages.graylog2.org/repo/packages/graylog-2.5-repository_latest.deb -O ${tmp_deb}
sudo dpkg -i ${tmp_deb}
sudo apt-get update && sudo apt-get install graylog-server
sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
#sudo systemctl start graylog-server.service

ipaddr=`/sbin/ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
test -f /etc/graylog/server/server.conf &&\
cp /etc/graylog/server/server.conf /etc/graylog/server/server.conf.$$ &&\
echo "root_timezone = Asia/Shanghai
#allow_highlighting = true
is_master = false
node_id_file = /etc/graylog/server/node-id
password_secret = 
root_password_sha2 = 
plugin_dir = /usr/share/graylog-server/plugin
web_listen_uri = http://0.0.0.0:9000/
rest_listen_uri = http://0.0.0.0:9000/api/
rest_transport_uri = http://${ipaddr}:9000/api/
web_endpoint_uri = http://graylog.server.local:9000/api/
web_enable = true
rotation_strategy = count
elasticsearch_max_docs_per_index = 20000000
elasticsearch_max_number_of_indices = 20
retention_strategy = delete
elasticsearch_shards = 4
elasticsearch_replicas = 0
elasticsearch_index_prefix = graylog
allow_leading_wildcard_searches = false
allow_highlighting = false
elasticsearch_analyzer = standard
output_batch_size = 500
output_flush_interval = 1
output_fault_count_threshold = 5
output_fault_penalty_seconds = 30
processbuffer_processors = 20
outputbuffer_processors = 40
processor_wait_strategy = blocking
ring_size = 65536
inputbuffer_ring_size = 65536
inputbuffer_processors = 2
inputbuffer_wait_strategy = blocking
message_journal_enabled = true
message_journal_dir = /var/lib/graylog-server/journal
lb_recognition_period_seconds = 3
mongodb_uri = mongodb://graylog:75PN76Db66En@graylog-proxy:27017,graylog-01:27017,graylog-02:27017/graylog?replicaSet=rs0
mongodb_max_connections = 1000
mongodb_threads_allowed_to_block_multiplier = 5
content_packs_dir = /usr/share/graylog-server/contentpacks
content_packs_auto_load = grok-patterns.json
proxied_requests_thread_pool_size = 32
elasticsearch_hosts = http://graylog-01:9200,http://graylog-02:9200,http://graylog-proxy:9200
elasticsearch_discovery_enabled = false" > /etc/graylog/server/server.conf
