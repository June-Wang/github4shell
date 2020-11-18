#!/bin/bash

path='/usr/local'
kafka_version='kafka_2.13-2.5.1'

test -d "${path}/${kafka_version}" &&\
eval "echo ${path}/${kafka_version} is found!;exit 1"

test -d ${path} ||\
mkdir -p ${path}

test -z "${JAVA_HOME}" &&\
eval "echo JAVA_HOME is null1.Please install jdk8.;exit 1" ||\
jdk_path=${JAVA_HOME}

id kafka >/dev/null 2>&1 ||\
useradd -M kafka -s /sbin/nologin

test -f ./${kafka_version}.tgz &&\
tar xzf ${kafka_version}.tgz -C ${path}/

test -d "${path}/${kafka_version}" &&\
ln -s ${path}/${kafka_version} ${path}/kafka

chown kafka.kafka -R ${path}/kafka ${path}/${kafka_version}

zookeeper_systemd_config='/etc/systemd/system/kafka-zookeeper.service'

test -f ${zookeeper_systemd_config} ||\
echo "[Unit]
Description=Apache Zookeeper server (Kafka)
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=kafka
Group=kafka
Environment=JAVA_HOME=${jdk_path}
ExecStart=${path}/kafka/bin/zookeeper-server-start.sh ${path}/kafka/config/zookeeper.properties
ExecStop=${path}/kafka/bin/zookeeper-server-stop.sh

[Install]
WantedBy=multi-user.target" > ${zookeeper_systemd_config}

chmod +x ${zookeeper_systemd_config} &&\
systemctl enable kafka-zookeeper.service

kafka_systemd_config='/etc/systemd/system/kafka.service'

test -f ${kafka_systemd_config} ||\
echo "[Unit]
Description=Apache Kafka server (broker)
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target remote-fs.target
After=network.target remote-fs.target kafka-zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka
Environment=JAVA_HOME=${jdk_path}
ExecStart=${path}/kafka/bin/kafka-server-start.sh ${path}/kafka/config/server.properties
ExecStop=${path}/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target" > ${kafka_systemd_config}

chmod +x ${kafka_systemd_config} &&\
systemctl enable kafka.service

kafka_data_path="${path}/kafka/data/kafka"
test -d ${kafka_data_path} || mkdir -p ${kafka_data_path}

kafka_config="${path}/kafka/config/server.properties"
test -f ${kafka_config} &&\
sed -r -i "s|^log.dirs=.*|log.dirs=${kafka_data_path}|" ${kafka_config}

firewall-cmd --zone=public --add-port=2181/tcp --permanent
firewall-cmd --zone=public --add-port=9092/tcp --permanent
firewall-cmd --reload

echo '### Reload systemd ###

systemctl daemon-reload
systemctl start kafka-zookeeper.service
systemctl start kafka.service
'

echo "### Single ###
vi ${path}/kafka/config/server.properties

#edit listeners propertie
listeners=PLAINTEXT://192.168.1.2:9092

### Cluster ###
vi ${path}/kafka/config/server.properties

#node1
broker.id=0
listeners=PLAINTEXT://192.168.1.156:9092
zookeeper.connect=192.168.1.156:2181,192.168.1.157:2181,192.168.1.158:2181

#node2
broker.id=1
listeners=PLAINTEXT://192.168.1.157:9092
zookeeper.connect=192.168.1.156:2181,192.168.1.157:2181,192.168.1.158:2181

#node3
broker.id=2
listeners=PLAINTEXT://192.168.1.158:9092
zookeeper.connect=192.168.1.156:2181,192.168.1.157:2181,192.168.1.158:2181

#TEST
${path}/kafka/bin/kafka-topics.sh --create --zookeeper node01:2181,node02:2181,node03:2181 --partitions 3 --replication-factor 1 --topic test"
