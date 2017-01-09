#!/bin/bash

yum_server='yum.server.local'
pkg='redis-3.2.6.tar.gz'

YUM_PACKAGE='zlib make ruby ruby-devel rubygems rpm-build'
USER='redis'
REDIS_PATH='/home'
PORTS='6380 6381 6382'

#SET TEMP DIR
INSTALL_DIR="/tmp/install_$$"
TEMP_FILE="/tmp/redis.conf.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR};test -f ${TEMP_FILE} && rm -f ${TEMP_FILE}"  EXIT

ls /usr/bin/yum >/dev/null 2>&1 ||\
eval "echo 未安装yum!;exit 1"

echo -en 'yum安装'
echo -en '\t->\t'
yum --skip-broken --nogpgcheck install -y ${YUM_PACKAGE} >/dev/null 2>&1 ||\
eval "echo yum安装失败;exit 1" && echo 'OK!'

echo -en '下载'
echo -en "${pkg}"
echo -en '\t->\t'
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1" &&\
echo 'OK!'

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"

pkg_path=`echo ${pkg}|sed 's/\.tar\.gz//'`
test -d ${pkg_path} && cd ${pkg_path} || \
eval "echo 未找到${pkg_path};exit 1"

echo -en '创建用户: '
echo -en "${USER}"
echo -en '\t->\t'
home_path="${REDIS_PATH}/${USER}"
id ${USER} >/dev/null 2>&1 || useradd -d ${home_path} -s /bin/bash -m ${USER}
test -d ${home_path} && echo 'OK!'||\
eval "echo ${home_path} 无法创建!;exit 1"

echo -en '编译中'
echo -en '\t->\t'
make_log="${home_path}/make_redis.log"
make PREFIX=${home_path} > ${make_log} 2>&1 || \
eval "echo 编译失败!错误详情请参阅: ${make_log};exit 1"
make PREFIX=${home_path} install >> ${make_log} 2>&1||\
eval "安装失败！;exit 1"

redis_cmd='mkreleasehdr.sh redis-trib.rb'
for file in `echo "${redis_cmd}" |sed -r 's/[ ]+/\n/g'`
do
        test -f src/${file} && cp src/${file} ${home_path}/bin/ ||\
        eval "echo 文件: src/${file} 未找到!"
done
echo 'OK!'

echo -en '创建文件夹'
echo -en '\t->\t'
redis_cluster_path="${home_path}/cluster"
mkdir -p ${redis_cluster_path}/{logs,run,data,conf}||\
eval "echo 创建文件夹(logs,run,data,config)失败!;exit 1" &&\
echo 'OK!'

echo -en '生成配置文件'
echo -en '\t->\t'
test -f redis.conf && grep -Ev '^#|^$' redis.conf > ${TEMP_FILE}
test -f ${TEMP_FILE} &&\
echo 'aof-rewrite-incremental-fsync yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
daemonize yes
unixsocket redis-6380.sock  
unixsocketperm 700' >> ${TEMP_FILE}

#dev='0.0.0.0'
addr=`ip address show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$|\.0$'|head -n1`
for port in `echo "${PORTS}" |sed -r 's/[ ]+/\n/g'`
do
        id="${port}"
        config_file="${home_path}/cluster/conf/redis-${id}.conf"
        sed -r -i "s|^pidfile.*|pidfile ${redis_cluster_path}/run/$redis-${id}.pid|" ${TEMP_FILE}
        sed -r -i "s|^port.*|port ${port}|g" ${TEMP_FILE}
        sed -r -i "s|^bind.*|bind ${addr}|g" ${TEMP_FILE}
        sed -r -i "s|^unixsocket.*|unixsocket ${redis_cluster_path}/run/redis-${id}.sock|" ${TEMP_FILE}
        sed -r -i "s|^logfile.*|logfile ${redis_cluster_path}/logs/redis-${id}.log|" ${TEMP_FILE}
        sed -r -i "s|^dbfilename.*|dbfilename dump-${id}.rdb|" ${TEMP_FILE}
        sed -r -i "s|^dir.*|dir ${redis_cluster_path}/data/|" ${TEMP_FILE}
        sed -r -i "s|^appendfilename.*|appendfilename appendonly-${id}.aof|" ${TEMP_FILE}
        sed -r -i "s|^cluster-config-file.*|cluster-config-file ${redis_cluster_path}/conf/nodes-${id}.conf|" ${TEMP_FILE}
        test -f ${TEMP_FILE} && cat ${TEMP_FILE}|sort -u > ${config_file}
done
echo 'OK!'

echo -en '设置系统参数'
echo -en '\t->\t'
grep transparent_hugepage /etc/rc.local >/dev/null 2>&1||\
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
echo never > /sys/kernel/mm/transparent_hugepage/enabled

grep overcommit_memory /etc/sysctl.conf >/dev/null 2>&1||\
echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
sysctl -w vm.overcommit_memory=1 >/dev/null 2>&1

grep somaxconn /etc/sysctl.conf >/dev/null 2>&1||\
echo 'net.core.somaxconn = 1024' >> /etc/rc.local
sysctl -w net.core.somaxconn=1024 >/dev/null 2>&1
echo 'OK!'

echo "find ${home_path}/ -type f -name 'nodes-*.conf'|xargs -r -i rm -f '{}'
find ${home_path}/ -type f -name '*.aof'|xargs -r -i rm -f '{}'
find ${home_path}/ -type f -name 'redis-*.conf'|xargs -r -i ${home_path}/bin/redis-server '{}'" > ${home_path}/bin/start_redis.sh
echo 'pkill redis-server' > ${home_path}/bin/stop_redis.sh
echo -en "/bin/bash ${home_path}/bin/stop_redis.sh\n sleep 5\n/bin/bash ${home_path}/bin/start_redis.sh\n" > ${home_path}/bin/restart_redis.sh


for port in `echo "${PORTS}" |sed -r 's/[ ]+/\n/g'`
do
        echo -en "${addr}:${port} "
done > ${TEMP_FILE}

ips=`cat ${TEMP_FILE}`

echo "${home_path}/bin/redis-trib.rb create --replicas 1 ${ips}" > ${home_path}/bin/start_redis_cluster.sh

chmod +x ${home_path}/bin/*.sh
chown -R ${USER}.${USER} ${home_path}

#timeout 30 gem install redis ||\
#eval "gem install redis 失败!;exit 1"
echo '1.安装: gem install redis'
echo '2.启动redis: start_redis_cluster.sh'
echo "3.启动redis群集: ${home_path}/bin/redis-trib.rb create --replicas 1 ${ips} nodes02:xxxx nodes02:xxxx nodes02:xxxx"
