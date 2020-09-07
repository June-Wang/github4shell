#!/bin/bash

YUM_PACKAGE='wget git unzip gcc gcc-c++ make cmake automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl openssl-devel'

#SET TEMP DIR
INSTALL_DIR="/tmp/install_$$"
TEMP_FILE="/tmp/tmp.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR};test -f ${TEMP_FILE} && rm -f ${TEMP_FILE}"  EXIT

test -f /etc/redhat-release ||\
eval "echo 不支持此系统!;exit 1"

test -f /usr/bin/yum ||\
eval "echo 未安装yum!;exit 1"

echo "yum 安装 ${YUM_PACKAGE}"
yum --skip-broken --nogpgcheck install -y ${YUM_PACKAGE} >/dev/null 2>&1 ||\
eval "echo yum安装${YUM_PACKAGE}失败;exit 1"

id fastdfs >/dev/null 2>&1 ||\
useradd fastdfs -M -s /sbin/nologin && \
eval "echo 用户: fastdfs 已经存在!"

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

#test -f /usr/local/lib/libfastcommon.so || \
#ln -s /usr/lib64/libfastcommon.so  /usr/local/lib/libfastcommon.so
#test -f /usr/lib/libfastcommon.so || \
#ln -s /usr/lib64/libfastcommon.so  /usr/lib/libfastcommon.so
#test -f /usr/local/lib/libfdfsclient.so ||\
#ln -s /usr/lib64/libfdfsclient.so /usr/local/lib/libfdfsclient.so
#test -f /usr/lib/libfdfsclient.so ||\
#ln -s /usr/lib64/libfdfsclient.so /usr/lib/libfdfsclient.so

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

#test -f /etc/init.d/fdfs_storaged &&\
#sed -r -i 's|/usr/local/bin/|/usr/bin/|g' /etc/init.d/fdfs_storaged
#test -f /etc/init.d/fdfs_trackerd &&\
#sed -r -i 's|/usr/local/bin/|/usr/bin/|g' /etc/init.d/fdfs_trackerd

cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
cp /etc/fdfs/client.conf.sample /etc/fdfs/client.conf #客户端文件，测试用

find ${INSTALL_DIR} -type f -name 'http.conf'|xargs -r -i mv '{}' /etc/fdfs/ #供nginx访问使用
find ${INSTALL_DIR} -type f -name 'mime.types'|xargs -r -i mv '{}' /etc/fdfs/ #供nginx访问使用

#fastdfs-nginx-module安装
#pkg='fastdfs-nginx-module_v1.16.tar.gz'
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
chown -R fastdfs.fastdfs ${module_path}
test -f ${module_path}/src/mod_fastdfs.conf &&\
cp ${module_path}/src/mod_fastdfs.conf /etc/fdfs/

#exit 0

#安装nginx
pkg='nginx-1.15.12.tar.gz'

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
./configure --prefix=/usr/local/nginx --user=fastdfs --group=fastdfs --add-module=/usr/local/fastdfs-nginx-module/src > ${log_file} 2>&1

make > ${log_file} 2>&1 && make install > ${log_file} 2>&1

test -f /usr/bin/nginx ||\
ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
test -d /etc/nginx ||\
ln -s /usr/local/nginx /etc/nginx

mkdir -p /fastdfs/storage/data
mkdir -p /fastdfs/tracker
#test -L /fastdfs/storage/data/M00 ||\
#ln -s /fastdfs/storage/data /fastdfs/storage/data/M00
chown -R fastdfs.fastdfs /fastdfs/storage/data
echo 'fastdfs安装完毕!'
