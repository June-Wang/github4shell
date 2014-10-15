#!/bin/bash

#SET ENV
YUM_SERVER='yum.suixingpay.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='bison ncurses-devel gcc gcc-c++ cmake make'
APT_PACKAGE='build-essential'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

#install mysql func
set_my_cnf () {
	mysql_socket_path='/var/lib/mysql'
	my_cnf='/etc/my.cnf'
        test -f /etc/my.cnf && backup_my='true'
	if [ "${backup_my}" == 'true' ];then
		mv /etc/my.cnf /etc/my.cnf.`date -d now +"%Y_%m%d.%H-%M-%S"`
	fi
        echo "[client]
port            = 3306
socket          = ${mysql_socket_path}/mysql.sock
[mysqld]
datadir=${DB_PATH}/mysql
basedir=/usr/local/mysql
log-error=${MYSQL_ERR_LOG_PATH}/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
log-bin=${DB_PATH}/mysql/binlog/mysql-bin
relay-log=${DB_PATH}/mysql/binlog/mysqld-relay-bin
innodb_data_home_dir=${DB_PATH}/mysql/innodata
character-set-server=utf8
max_binlog_cache_size=8M
max_binlog_size=1G
expire_logs_days = 30
binlog-ignore-db = test
#binlog-ignore-db = information_schema
#default-storage-engine=MyISAM
default-storage-engine=innodb
port            = 3306
socket          = ${mysql_socket_path}/mysql.sock
skip-external-locking
key_buffer_size = 384M
max_allowed_packet = 1M
table_open_cache = 512
sort_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size = 32M
thread_concurrency = 8
server-id       = 1
[mysqldump]
quick
max_allowed_packet = 16M
[mysql]
no-auto-rehash
[myisamchk]
key_buffer_size = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M
[mysqlhotcopy]
interactive-timeout" > ${my_cnf}

#set default value
mkdir -p ${mysql_socket_path}
chown -R ${DB_USER}:${DB_USER} ${mysql_socket_path}
#local socket_file='/var/lib/mysql/mysql.sock'
#test -f "${socket_file}" && rm -f "${socket_file}"
#ln -s /tmp/mysql.sock ${socket_file}
}

main () {
#VALUE FOR MYSQL
DB_PATH='/data'
DB_USER='mysql'
MYSQL_ERR_LOG_PATH='/var/log/mysql'

#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd

#Install mysql 5.5.35
PACKAGE='mysql-5.5.35.tar.gz'

#Created user
create_user "${DB_USER}" "bash"
create_tmp_dir
download_and_check
run_cmds "cmake \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DSYSCONFDIR=/etc/ \
-DMYSQL_DATADIR=${DB_PATH}/mysql \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DEXTRA_CHARSETS=all \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DMYSQL_TCP_PORT=3306" 'make' 'make install'
#cd ..
mkdir -p /var/run/mysqld ${DB_PATH}/mysql/{binlog,innodata} ${MYSQL_ERR_LOG_PATH}
chown -R ${DB_USER}:${DB_USER} ${DB_PATH}/mysql /var/run/mysqld ${MYSQL_ERR_LOG_PATH}
chmod 700 ${DB_PATH}/mysql/{binlog,innodata} ${MYSQL_ERR_LOG_PATH}
test ! -e /etc/profile.d/mysql_env.sh && echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql_env.sh
source /etc/profile.d/mysql_env.sh
test -e  /usr/local/mysql/scripts/mysql_install_db &&\
/usr/local/mysql/scripts/mysql_install_db --basedir=/usr/local/mysql/ --datadir=${DB_PATH}/mysql --user=${DB_USER}
#ln -s /usr/local/mysql/bin/* /usr/bin/
test -e /usr/local/mysql/support-files/mysql.server && cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld
test -e /etc/rc.d/init.d/mysqld && chmod 755 /etc/rc.d/init.d/mysqld

set_my_cnf
set_auto_run 'mysqld'

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
