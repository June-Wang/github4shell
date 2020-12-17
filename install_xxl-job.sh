#!/bin/bash

jdk_pkg='jdk-8u231-linux-x64.rpm'
admin_pkg='xxl-job-admin-2.1.2.jar'
exe_pkg='xxl-job-executor-sample-springboot-2.1.2.jar'
path='/usr/local'

test -f ${jdk_pkg} &&\
rpm -ivh ${jdk_pkg} ||\
eval "echo ${jdk_pkg} not found!;exit 1"

test -d ${path}/xxl-job/ &&\
eval "echo ${path}/xxl-job exist!;exit 1" ||\
mkdir -p ${path}/xxl-job

test -f ${admin_pkg} &&\
cp ${admin_pkg} ${path}/xxl-job/ ||\
eval "echo ${admin_pkg} not found!;exit 1"

test -f ${exe_pkg} &&\
cp ${exe_pkg} ${path}/xxl-job/ ||\
eval "echo ${exe_pkg} not found!;exit 1"

test -f ${path}/xxl-job/xxl-job-admin-start.sh ||\
echo "#!/bin/bash
nohup java -jar ${path}/xxl-job/${admin_pkg} >/dev/null 2>&1 &
" > ${path}/xxl-job/xxl-job-admin-start.sh

test -f ${path}/xxl-job/xxl-job-executor-start.sh ||\
echo "#!/bin/bash
nohup java -jar ${path}/xxl-job/${exe_pkg} >/dev/null 2>&1 &
" > ${path}/xxl-job/xxl-job-executor-start.sh

test -f ${path}/xxl-job/xxl-job-admin-stop.sh ||\
echo "#!/bin/bash
ps -eo pid,args|grep 'xxl-job-admin'|grep -v grep|awk '{print \$1}'|xargs -r -i kill '{}' >/dev/null 2>&1
" > ${path}/xxl-job/xxl-job-admin-stop.sh

test -f ${path}/xxl-job/xxl-job-executor-stop.sh ||\
echo "#!/bin/bash
ps -eo pid,args|grep 'xxl-job-executor'|grep -v grep|awk '{print \$1}'|xargs -r -i kill '{}' >/dev/null 2>&1
" > ${path}/xxl-job/xxl-job-executor-stop.sh

chmod +x ${path}/xxl-job/*.sh

test -f /usr/lib/systemd/system/xxl-job-admin.service ||\
echo "[Unit]
Description=xxl-job-admin
After=syslog.target network.target

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65536
LimitNPROC=65536
WorkingDirectory=${path}/xxl-job/
ExecStart=${path}/xxl-job/xxl-job-admin-start.sh
ExecStop=${path}/xxl-job/xxl-job-admin-stop.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/xxl-job-admin.service

test -f /usr/lib/systemd/system/xxl-job-executor.service ||\
echo "[Unit]
Description=xxl-job-executor
After=syslog.target network.target

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65536
LimitNPROC=65536
WorkingDirectory=${path}/xxl-job/
ExecStart=${path}/xxl-job/xxl-job-executor-start.sh
ExecStop=${path}/xxl-job/xxl-job-executor-stop.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/xxl-job-executor.service

systemctl daemon-reload
systemctl enable xxl-job-admin.service
systemctl enable xxl-job-executor.service

firewall-cmd --zone=public --add-port=38080-38081/tcp --permanent
firewall-cmd --zone=public --add-port=39999/tcp --permanent
firewall-cmd --reload

echo 'service xxl-job-admin start
service xxl-job-executor start

xxl-admin:
curl http://localhost:38080/xxl-job-admin/toLogin
'
