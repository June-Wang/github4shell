#!/bin/bash

#pkg_url='https://github.com/Graylog2/collector-sidecar/releases/download/0.1.6/collector-sidecar_0.1.6-1_amd64.deb'
pkg_url='https://github.com/Graylog2/collector-sidecar/releases/download/0.1.8/collector-sidecar_0.1.8-1_amd64.deb'
tmp_file='/tmp/collector-sidecar.deb'

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

wget ${pkg_url} -O /tmp/collector-sidecar.deb ||\
eval "echo download ${pkg_url} fail!;exit 1"

test -f ${tmp_file} &&\
sudo /usr/bin/dpkg -i ${tmp_file}

test -f /usr/bin/graylog-collector-sidecar
sudo /usr/bin/graylog-collector-sidecar -service install

sudo systemctl enable collector-sidecar.service

coll_server='172.24.0.70'
ip=`/sbin/ip addr list|grep -A1 eth0|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
coll_config='/etc/graylog/collector-sidecar/collector_sidecar.yml'
test -f ${coll_config} &&\
echo "server_url: http://${coll_server}:9000/api/
node_id: ${ip}
update_interval: 10
tls_skip_verify: false
send_status: true
list_log_files:
collector_id: file:/etc/graylog/collector-sidecar/collector-id
cache_path: /var/cache/graylog/collector-sidecar
log_path: /var/log/graylog/collector-sidecar
log_rotation_time: 86400
log_max_age: 604800
tags:
    - jump_log
#    - apache
backends:
    - name: nxlog
      enabled: false
      binary_path: /usr/bin/nxlog
      configuration_path: /etc/graylog/collector-sidecar/generated/nxlog.conf
    - name: filebeat
      enabled: true
      binary_path: /usr/bin/filebeat
      configuration_path: /etc/graylog/collector-sidecar/generated/filebeat.yml" > ${coll_config}
