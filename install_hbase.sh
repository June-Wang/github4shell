#!/bin/bash

pkg='hbase-1.2.12-bin.tar.gz'
path='/usr/local'
hbase_data_path="${path}/base/data"
jdk_pkg='jdk-8u231-linux-x64.rpm'
java_home='/usr/java/jdk1.8.0_231-amd64'

test -f ${jdk_pkg} ||\
eval "echo ${jdk_pkg} not found!;exit 1" &&\
rpm -ivh ${jdk_pkg}

test -f ${pkg} ||\
eval "echo ${pkg} not found!;exit 1"

test -d ${path} ||\
mkdir -p ${path} 

test -d ${path}/hbase ||\
tar xzf ${pkg} -C ${path}

path_name=`echo ${pkg}|sed 's/-bin.tar.gz//'`
ln -s ${path}/${path_name} ${path}/hbase

echo "[Unit]
Description=HBase Hadoop database
After=network.target

[Service]
Type=forking
Environment=JAVA_HOME=${java_home}
ExecStart=${path}/hbase/bin/start-hbase.sh
ExecStop=${path}/hbase/bin/stop-hbase.sh
#User=hbase
#Group=hbase

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/hbase.service

#chmod +x /usr/lib/systemd/system/hbase.service
systemctl daemon-reload
systemctl enable hbase.service

firewall-cmd --zone=public --add-port=16010/tcp --permanent
firewall-cmd --zone=public --add-port=2181/tcp --permanent
firewall-cmd --zone=public --add-port=39374/tcp --permanent
firewall-cmd --reload

test -f ${path}/hbase/conf/hbase-site.xml &&\
cp ${path}/hbase/conf/hbase-site.xml ${path}/hbase/conf/hbase-site.xml.bak.$$

test -d ${hbase_data_path} ||\
mkdir -p ${hbase_data_path}

echo "<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file://${hbase_data_path}</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>${hbase_data_path}/zookeeper</value>
  </property>
</configuration>
" > ${path}/hbase/conf/hbase-site.xml

#test -f hbase-create.hbase &&\
#${path}/hbase/bin/hbase shell ./hbase-create.hbase

test -f /etc/profile.d/jdk_env.sh ||\
echo "export JAVA_HOME=${java_home}
export JAVA_BIN=${java_home}/bin
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH" > /etc/profile.d/jdk_env.sh

echo "service hbase.service start
service hbase.service status
export JAVA_HOME=${java_home}
${path}/hbase/bin/hbase shell ./hbase-create.hbase
"
