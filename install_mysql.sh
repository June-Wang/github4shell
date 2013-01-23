#!/bin/bash

init_var () {
yum_server="$1"
file_name="$2"
yum_para="$3"
if [ "${yum_para}" = 'lan' ];then
	YUM='yum --disablerepo=\* --enablerepo=centos5-lan'
else
	YUM='yum'
fi
package_url="http://${yum_server}/tools/${file_name}"
}

create_user () {
	username="$1"
	if `grep 'mysql' /etc/passwd >/dev/null 2>&1`; then
		echo 'Users have been created!'
	else
		/usr/sbin/groupadd mysql
		/usr/sbin/useradd -g mysql mysql
	fi
}

install_lib () {
log_name="$1"
log_file="${local_path}/yum_for_${log_name}.log"
yum_pkg="$2"
echo -n "install bison ncurses-devel gcc gcc-c++ cmake please wait ...... "
eval "${YUM} install -y bison ncurses-devel gcc gcc-c++ cmake >${log_file} 2>&1" || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo -e "yum not available!\nview error please type: less ${log_file}" 1>&2
        exit 1
fi
echo "done."
}

make_tmp_dir () {
mkdir -p "${local_path}/${install_dir}" && cd "${local_path}/${install_dir}" || mkdir_dir='fail'
if [ "${mkdir_dir}" = "fail"  ];then
        echo "mkdir ${install_dir} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
test -d "${local_path}/${install_dir}" && rm -rf "${local_path}/${install_dir}"
}

check_urls () {
for url in "$@"
do
        file=`echo ${url}|awk -F'/' '{print $NF}'`
        if [ ! -f "${file}" ]; then
                echo -n "download ${url} ...... "
                wget -q "${url}"  && echo 'done.' || download='fail'
                if [ "${download}" = "fail" ];then
                        echo "download ${url} fail!" 1>&2 && del_tmp
                        exit 1
                fi
        fi
done
}

install_pre () {
        install_url="$1"
        file=`echo ${install_url}|awk -F'/' '{print $NF}'`
        dir=`echo ${file}|awk -F'.tar' '{print $1}'`
        test -e "${file}" && tar xzf ${file} || tar_file='not_exist'
        cd ${dir} || file_dir='not_exist'
        if [ "${tar_file}" = 'not_exist' ];then
                echo "${file} not exist!" 1>&2 && del_tmp
                exit 1
        fi
        if [ "${file_dir}" = 'not_exist' ];then
                echo "plesse check ${file}!" 1>&2 && del_tmp
                exit 1
        fi
        echo -n "Compile ${dir} please wait ...... "
}

run_cmds () {
        cmd_log="${local_path}/install_${dir}.log"
        #test -f "${cmd_log}" && cat /dev/null > "${local_path}/install_${dir}.log"
        test -f "${cmd_log}" && cat /dev/null > "${cmd_log}"
        for cmd in "$@"
        do
                ${cmd} >> "${cmd_log}" 2>&1 || compile='fail'
                if [ "${compile}" = 'fail' ]; then
                        echo "run ${cmd} error! please type: less ${cmd_log}" 1>&2 && del_tmp
                        exit 1
                fi
        done
        echo "done."
}

install_mysql () {
	install_pre "${package_url}"
	run_cmds 'cmake \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DSYSCONFDIR=/etc/ \
-DMYSQL_DATADIR=/data/mysql \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DEXTRA_CHARSETS=all \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DMYSQL_TCP_PORT=3306' 'make' 'make install'
	cd ..
	#test -e /usr/local/mysql/support-files/my-huge.cnf && cp /usr/local/mysql/support-files/my-huge.cnf /etc/my.cnf
	mkdir -p /data/mysql/innodata
	mkdir -p /var/run/mysqld
	mkdir -p /data/mysql/binlog
	chown -R mysql:mysql /data/mysql
	chown -R mysql:mysql /var/run/mysqld
	chmod 700 /data/mysql/binlog /data/mysql/innodata
	test ! -e /etc/profile.d/mysql_env.sh && echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql_env.sh
	source /etc/profile.d/mysql_env.sh
	test -e  /usr/local/mysql/scripts/mysql_install_db &&\
	/usr/local/mysql/scripts/mysql_install_db --basedir=/usr/local/mysql/ --datadir=/data/mysql --user=mysql
}

set_my_cnf () {
	test ! -e /etc/my.cnf &&\
	echo '[client]
port            = 3306
socket          = /tmp/mysql.sock
[mysqld]
datadir = /data/mysql
basedir=/usr/local/mysql
log-error=/var/log/mysql.log
pid-file=/var/run/mysqld/mysqld.pid
log-bin=/data/mysql/binlog/mysql-bin
relay-log=/data/mysql/binlog/mysqld-relay-bin
innodb_data_home_dir=/data/mysql/innodata
max_binlog_cache_size=8M
max_binlog_size=1G
expire_logs_days = 30
# 不需要备份的数据库，多个写多行
binlog-ignore-db = test
#binlog-ignore-db = information_schema
#default-storage-engine=MyISAM
default-storage-engine=innodb
port            = 3306
socket          = /tmp/mysql.sock
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
interactive-timeout' > /etc/my.cnf
}

set_auto_run () {
	test -e /usr/local/mysql/support-files/mysql.server && cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld
	test -e /etc/rc.d/init.d/mysqld && chmod 755 /etc/rc.d/init.d/mysqld
	chkconfig --add mysqld
	chkconfig mysqld on
}

echo_bye () {
	program="$1"
	echo "Install ${program} complete! Please type : /etc/init.d/${program} start " && exit 0
}

main () {
my_project='mysqld'
init_var 'yum.suixingpay.com' 'mysql-5.5.25a.tar.gz' 'lan'
install_lib "${my_project}" 'bison ncurses-devel gcc gcc-c++ cmake'
make_tmp_dir
create_user "${my_project}"
check_urls "${package_url}"
install_mysql
set_my_cnf
set_auto_run
del_tmp
echo_bye "${my_project}"
}

#local install path
local_path='/usr/local/src'
install_dir="install_$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${install_dir}"  EXIT
main
