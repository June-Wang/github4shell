#!/bin/bash

pkg="$1"
java_path='/usr/java/jdk1.8.0_231-amd64'
path="/opt/doris"
java_pkg='jdk-8u231-linux-x64.rpm'

test -d ${path} ||\
mkdir -p ${path}

test -z "${pkg}" &&\
eval "echo ./install.sh be or ./install.sh fe;exit 1"

if [ "X${pkg}" == "Xbe" ];then
   test -f /usr/lib/systemd/system/doris-be.service &&\
   eval "echo doris-be already exist!;exit 1"

   test -f ./be.tar.gz && tar xzf be.tar.gz -C ${path} 

   echo "[Unit]
Description=doris be
After=syslog.target network.target

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65536
LimitNPROC=65536
WorkingDirectory=${path}/be/
ExecStart=${path}/be/start-be.sh
ExecStop=cd ${path}/be/bin && /bin/bash stop_be.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/doris-be.service

   systemctl daemon-reload
   systemctl enable doris-be.service

   firewall-cmd --state |grep 'not running' >/dev/null 2>&1 && exit 0
   firewall-cmd --add-port=9060/tcp --permanent
   firewall-cmd --add-port=8040/tcp --permanent
   firewall-cmd --add-port=9050/tcp --permanent
   firewall-cmd --add-port=8060/tcp --permanent
   firewall-cmd --reload
elif [ "X${pkg}" == "Xfe" ]; then
   test -f /usr/lib/systemd/system/doris-fe.service &&\
   eval "echo doris-fe already exist!;exit 1"

   test -f ${java_pkg} ||\
   eval "echo ${java_pkg} not found!;exit 1" &&\
   rpm -ivh ${java_pkg}

   test -f ./fe.tar.gz && tar xzf fe.tar.gz -C ${path}

   test -f ${path}/fe/start-fe.sh &&\
   sed -r -i "s|export JAVA.+$|export JAVA_HOME=${java_path}|" ${path}/fe/start-fe.sh
echo "[Unit]
Description=doris fe
After=syslog.target network.target

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65536
LimitNPROC=65536
WorkingDirectory=${path}/fe/
ExecStart=${path}/fe/start-fe.sh
ExecStop=cd ${path}/fe/bin && /bin/bash stop_fe.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/doris-fe.service

    systemctl daemon-reload
    systemctl enable doris-fe.service
    firewall-cmd --state |grep 'not running' >/dev/null 2>&1 && exit 0
    firewall-cmd --add-port=8030/tcp --permanent
    firewall-cmd --add-port=9020/tcp --permanent
    firewall-cmd --add-port=9030/tcp --permanent
    firewall-cmd --add-port=9010/tcp --permanent
    firewall-cmd --reload 

else
    eval "echo ./install.sh be or ./install.sh fe;exit 1"
fi

echo '
1. service doris-fe start
2. service doris-be start'
echo '
mysql -h localhost -P 9030 -uroot -e "\
ALTER SYSTEM ADD BACKEND 'HOST1:9050';
ALTER SYSTEM ADD BACKEND 'HOST2:9050';
ALTER SYSTEM ADD BACKEND 'HOST3:9050';
"'

