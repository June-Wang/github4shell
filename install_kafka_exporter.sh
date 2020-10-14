#!/bin/bash

netstat -nlpt|grep ':9308 ' >/dev/null 2>&1 && exit 0

kafka_server='10.0.0.1:9092'
file='kafka_exporter-1.2.0.linux-amd64.tar.gz'
tmp_path="/tmp/kafka_exporter"
install_path='/usr/local/prometheus/'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${tmp_path} && rm -rf ${tmp_path}"  EXIT

test -d ${tmp_path} ||\
mkdir -p ${tmp_path}

wget http://yum.server.local/tools/${file} -O ${tmp_path}/${file} ||\
eval "echo wget fail!;exit 1"

test -d ${install_path} ||\
mkdir -p ${install_path}

cd ${tmp_path} &&\
tar xzf ${file} 

dir_name=`echo "${file}"|sed 's/.tar.gz//'`
mv ${dir_name} ${install_path}kafka_exporter

id prometheus >/dev/null 2>&1 ||\
useradd --no-create-home -s /bin/false prometheus

chown -R prometheus:prometheus ${install_path}kafka_exporter/

test -f /usr/lib/systemd/system/kafka_exporter.service||\
echo "[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=${install_path}kafka_exporter/kafka_exporter --kafka.server=${kafka_server}

[Install]
WantedBy=default.target" > /usr/lib/systemd/system/kafka_exporter.service

systemctl enable --now kafka_exporter.service
firewall-cmd --permanent --add-port=9308/tcp
firewall-cmd --reload
