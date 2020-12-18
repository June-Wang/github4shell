#!/bin/bash

test -d /etc/fdfs &&\
eval "echo fastdfs 已经安装!;exit 1"

YUM_PACKAGE='wget git unzip gcc gcc-c++ make cmake automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl openssl-devel'

#SET TEMP DIR
INSTALL_DIR="/tmp/install_$$"
TEMP_FILE="${INSTALL_DIR}/tmp.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR}"  EXIT

test -f /etc/redhat-release ||\
eval "echo 不支持此系统!;exit 1"

test -f /usr/bin/yum ||\
eval "echo 未安装yum!;exit 1"

echo "yum 安装 ${YUM_PACKAGE}"
yum --skip-broken --nogpgcheck install -y ${YUM_PACKAGE} >/dev/null 2>&1 ||\
eval "echo yum安装${YUM_PACKAGE}失败;exit 1"

#id fastdfs >/dev/null 2>&1 ||\
#useradd fastdfs -M -s /sbin/nologin && \
#eval "echo 用户: fastdfs 已经存在!"

#libfastcommon安装
#pkg='libfastcommon-master.zip'
pkg='libfastcommon-1.0.43.tar.gz'

echo "安装${pkg}"
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
test -f ./${pkg} ||\
eval "echo ${pkg} not found!;exit 1" &&\
cp ${pkg} ${INSTALL_DIR}/

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} >/dev/null 2>&1||\
eval "echo ${pkg}不存在;exit 1"

pkg_path=`echo "${pkg}"|sed 's/.tar.gz//'`
cd ${pkg_path}||\
eval "解压失败!;exit 1"

log_file="/tmp/install_${pkg}.log"
./make.sh > ${log_file} 2>&1 && ./make.sh install > ${log_file} 2>&1||\
eval "编译失败!;exit 1"

test -f /usr/local/lib/libfastcommon.so || \
ln -s /usr/lib64/libfastcommon.so  /usr/local/lib/libfastcommon.so
test -f /usr/lib/libfastcommon.so || \
ln -s /usr/lib64/libfastcommon.so  /usr/lib/libfastcommon.so
test -f /usr/local/lib/libfdfsclient.so ||\
ln -s /usr/lib64/libfdfsclient.so /usr/local/lib/libfdfsclient.so
test -f /usr/lib/libfdfsclient.so ||\
ln -s /usr/lib64/libfdfsclient.so /usr/lib/libfdfsclient.so

#fastdfs安装
pkg='fastdfs-6.06.tar.gz'

echo "安装${pkg}"
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}

cd
test -f ./${pkg} &&\
cp ${pkg} ${INSTALL_DIR}/ ||\
eval "echo ${pkg} not found!;exit 1"

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} >/dev/null 2>&1 ||\
eval "echo ${pkg}不存在;exit 1"

pkg_path=`echo "${pkg}"|sed 's/.tar.gz//'`
cd ${pkg_path}||\
eval "解压失败!;exit 1"

log_file="/tmp/install_${pkg}.log"
./make.sh > ${log_file} 2>&1 && ./make.sh install > ${log_file} 2>&1 ||\
eval "编译失败!;exit 1"

test -f /etc/init.d/fdfs_storaged &&\
sed -r -i 's|/usr/local/bin/|/usr/bin/|g' /etc/init.d/fdfs_storaged
test -f /etc/init.d/fdfs_trackerd &&\
sed -r -i 's|/usr/local/bin/|/usr/bin/|g' /etc/init.d/fdfs_trackerd

cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
cp /etc/fdfs/client.conf.sample /etc/fdfs/client.conf
#客户端文件，测试用

find ${INSTALL_DIR} -type f -name 'http.conf'|xargs -r -i mv '{}' /etc/fdfs/
#供nginx访问使用
find ${INSTALL_DIR} -type f -name 'mime.types'|xargs -r -i mv '{}' /etc/fdfs/
#供nginx访问使用

#test -d /etc/fdfs/ &&\
#chown fastdfs.fastdfs -R /etc/fdfs/

cat > /usr/lib/systemd/system/tracker.service <<EOF
[Unit]
Description=The FastDFS File server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf start
ExecStop=/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf stop
ExecRestart=/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf restart

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tracker

cat >/usr/lib/systemd/system/storage.service <<EOF

[Unit]
Description=The FastDFS File server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/bin/fdfs_storaged /etc/fdfs/storage.conf start
ExecStop=/usr/bin/fdfs_storaged /etc/fdfs/storage.conf stop
ExecRestart=/usr/bin/fdfs_storaged /etc/fdfs/storage.conf restart

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable storage

#fastdfs-nginx-module安装
pkg='fastdfs-nginx-module-1.22.tar.gz'

echo "安装${pkg}"
cd
test -f ./${pkg} &&\
cp ${pkg} ${INSTALL_DIR}/ ||\
eval "echo ${pkg} not found!;exit 1"

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} >/dev/null 2>&1 ||\
eval "echo ${pkg}不存在;exit 1"

pkg_path=`echo "${pkg}"|sed 's/.tar.gz//'`

#test -f ${pkg_path}/src/config && \
#sed -r -i '/^CORE_INCS/s|/usr/local/|/usr/|g' ${pkg_path}/src/config

module_path='/usr/local/fastdfs-nginx-module'
test -d ${module_path} || mv ${pkg_path} /usr/local/
test -d ${module_path} ||\
ln -s /usr/local/${pkg_path} ${module_path}
test -d ${module_path}
#chown -R fastdfs.fastdfs ${module_path}
test -f ${module_path}/src/mod_fastdfs.conf &&\
cp ${module_path}/src/mod_fastdfs.conf /etc/fdfs/

#exit 0

#安装nginx
pkg='nginx-1.16.1.tar.gz'

echo "安装${pkg}"
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}

cd
test -f ./${pkg} &&\
cp ${pkg} ${INSTALL_DIR}/ ||\
eval "echo ${pkg} not found!;exit 1"

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} >/dev/null 2>&1 ||\
eval "echo ${pkg}不存在;exit 1"

#id fastdfs >/dev/null 2>&1 ||\
#useradd fastdfs -M -s /sbin/nologin && \
#eval "echo 用户: fastdfs 已经存在!"

log_file="/tmp/install_${pkg}.log"
pkg_path=`echo "${pkg}"|sed 's/.tar.gz//'`
cd ${pkg_path} && \
./configure --prefix=/usr/local/nginx \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_gzip_static_module \
--add-module=/usr/local/fastdfs-nginx-module/src > ${log_file} 2>&1

make >> ${log_file} 2>&1 && make install >> ${log_file} 2>&1

test -f /usr/bin/nginx ||\
ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
test -d /etc/nginx ||\
ln -s /usr/local/nginx /etc/nginx

test -f /usr/lib/systemd/system/nginx.service ||\
echo '[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
#PIDFile=/tmp/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/nginx.service

nginx_conf_path='/usr/local/nginx/conf.d'
test -d ${nginx_conf_path} ||\
mkdir -p ${nginx_conf_path}

nginx_config='/usr/local/nginx/conf/nginx.conf'

grep -E '^#SET NGINX' ${nginx_config} ||\
echo '#SET NGINX
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    #access_log  logs/access.log  main;

    sendfile        on;
    keepalive_timeout  65;
    server_names_hash_bucket_size 128;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 300m;
    proxy_redirect off;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_connect_timeout 90;
    proxy_send_timeout 90;
    proxy_read_timeout 90;
    proxy_buffer_size 16k;
    proxy_buffers 4 64k;
    proxy_busy_buffers_size 128k;
    proxy_temp_file_write_size 128k;
    proxy_cache_path /usr/local/nginx/nginx_cache keys_zone=http-cache:100m;
    include /usr/local/nginx/conf.d/*.conf;
}
' > ${nginx_config}

systemctl daemon-reload
systemctl enable nginx.service

echo '开启防火墙端口22122/23000'
firewall-cmd --zone=public --add-port=23000/tcp --permanent
firewall-cmd --zone=public --add-port=22122/tcp --permanent
firewall-cmd --reload

echo 'fastdfs安装完毕!'

#chown -R fastdfs.fastdfs /fastdfs/
echo '>>>>>> README <<<<<<
配置fastdfs请参考链接
http://soft.hxmec.com/soft/fastdfs/%E6%90%AD%E5%BB%BA%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9FFastDFS%E9%9B%86%E7%BE%A4.pdf

1. 启动stracker
systemctl start tracker
2. 启动sotrage
systemctl start storage
3. 启动nginx
systemctl start nginx
'
