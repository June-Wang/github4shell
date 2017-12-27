#!/bin/bash

yum_server='yum.server.local'
jdk_pkg='jdk-7u45-linux-x64.tar.gz'
jdk_path='/usr/java'

test -d ${jdk_path} && \
#test -n "${JAVA_HOME}" && \
eval "echo 本地JDK已经安装，请删除${jdk_path}目录后继续安装!;exit 1"

url="http://${yum_server}/tools/${jdk_pkg}"
echo -en '下载\t'
echo -en "${jdk_pkg}"
echo -en '\t->\t'

#异常退出删除临时文件
temp_file="/tmp/${jdk_pkg}"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${temp_file} && rm -f ${temp_file}"  EXIT

wget -q ${url} -O /tmp/${jdk_pkg} && echo ok ||\
eval "echo fail;exit 1"

echo -en '解压缩\t'
echo -en "${jdk_pkg}"
echo -en '\t->\t'
cd /tmp/ && tar xzf ${jdk_pkg} && echo ok ||\
eval "echo fail;exit 1"

jdk_dir=`find /tmp/ -maxdepth 1 -type d -name "jdk*"|awk -F'/' '{print $NF}'`

echo -en '安装\t'
echo -en "${jdk_dir}"
echo -en '\t->\t'
test -d ${jdk_path} || mkdir -p ${jdk_path}
mv /tmp/${jdk_dir} ${jdk_path}/ && echo ok ||\
eval "echo fail;exit 1"
chown root.root -R ${jdk_path}

echo -en '配置\t'
echo -en "${jdk_dir}"
echo -en '\t->\t'
echo "export JAVA_HOME=${jdk_path}/${jdk_dir}
export JAVA_BIN=${jdk_path}/${jdk_dir}/bin
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH" > /etc/profile.d/jdk_env.sh && \
echo ok ||\
eval "echo fail;exit 1"

test -f /etc/profile.d/jdk_env.sh &&\
source /etc/profile.d/jdk_env.sh
sed -r -i.bak 's|^securerandom.source=.*|securerandom.source=file:/dev/./urandom|' $JAVA_HOME/jre/lib/security/java.security

echo '激活JDK配置，请断开当前会话，并重新登陆!'
echo bye
