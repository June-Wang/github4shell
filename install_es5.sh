#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
sudo echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update && sudo apt-get install elasticsearch -y
test -f /etc/elasticsearch/log4j2.properties &&\
sed -r -i 's/^logger.action.level.*$/logger.action.level = info/g' /etc/elasticsearch/log4j2.properties

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
