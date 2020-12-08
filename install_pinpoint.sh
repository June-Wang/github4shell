#!/bin/bash

path='/usr/local'
coll_pkg='pinpoint-collector-boot-2.2.0.jar'
web_pkg='pinpoint-web-boot-2.2.0.jar'

test -d ${path}/pinpoint &&\
eval "echo pinpoint already exists;exit 0"

mkdir -p ${path}/pinpoint

test -f ${coll_pkg} &&\
cp ${coll_pkg} ${path}/pinpoint/ ||\
eval "echo ${coll_pkg} not found!;exit 1"

test -f ${web_pkg} &&\
cp ${web_pkg} ${path}/pinpoint/ ||\
eval "echo ${web_pkg} not found!;exit 1"

echo "#!/bin/bash

cd ${path}/pinpoint &&\
nohup java -jar -Dpinpoint.zookeeper.address=localhost ${coll_pkg} > pinpoint-collector.log &" > ${path}/pinpoint/pinpoint-collector-start.sh

echo "#!/bin/bash

ps -eo pid,args|grep pinpoint-collector|grep -v grep|awk '{print \$1}'|xargs -r -i kill '{}'
" > ${path}/pinpoint/pinpoint-collector-stop.sh

echo "#!/bin/bash

cd ${path}/pinpoint &&\
nohup java -jar -Dpinpoint.zookeeper.address=localhost ${web_pkg} > pinpoint-web.log &" > ${path}/pinpoint/pinpoint-web-start.sh

echo "#!/bin/bash

ps -eo pid,args|grep pinpoint-web|grep -v grep|awk '{print $1}'|xargs -r -i kill '{}'
" > ${path}/pinpoint/pinpoint-web-stop.sh

chmod +x ${path}/pinpoint/*.sh

echo "[Unit]
Description=pinpoint-web
After=syslog.target network.target

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65536
LimitNPROC=65536
WorkingDirectory=${path}/pinpoint/
ExecStart=${path}/pinpoint/pinpoint-web-start.sh
ExecStop=${path}/pinpoint/pinpoint-web-stop.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/pinpoint-web.service

echo "[Unit]
Description=pinpoint-collector
After=syslog.target network.target

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65536
LimitNPROC=65536
WorkingDirectory=${path}/pinpoint/
ExecStart=${path}/pinpoint/pinpoint-collector-start.sh
ExecStop=${path}/pinpoint/pinpoint-collector-stop.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/pinpoint-collector.service

systemctl daemon-reload
systemctl enable pinpoint-web.service
systemctl enable pinpoint-collector.service

firewall-cmd --zone=public --add-port=8080-8081/tcp --permanent
firewall-cmd --zone=public --add-port=9991-9994/tcp --permanent
firewall-cmd --reload

echo "service pinpoint-collector start
service pinpoint-web start"
