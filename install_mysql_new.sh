#!/bin/bash

check_system (){
SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                SYSTEM='centos5'
                YUM_SOURCE_NAME='centos5-lan'
                CONFIG_CMD='chkconfig'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                SYSTEM='rhel5'
                YUM_SOURCE_NAME='RHEL5-lan'
                CONFIG_CMD='chkconfig'
                ;;
        'Red Hat Enterprise Linux Server release 6'*)
                SYSTEM='rhel6'
                YUM_SOURCE_NAME='RHEL6-lan'
                CONFIG_CMD='chkconfig'
                ;;
#        'Debian GNU/Linux 6'*)
#                SYSTEM='debian6'
#                CONFIG_CMD='sysv-rc-conf'
#                ;;
#        'Debian GNU/Linux 7'*)
#                SYSTEM='debian7'
#                CONFIG_CMD='sysv-rc-conf'
#                ;;
        *)
                SYSTEM='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

set_install_cmd () {
local para="$1"
case "${SYSTEM}" in
    centos5|rhel5|rhel6)
        local install_cmd='yum --skip-broken --nogpgcheck'
        local package="${YUM_PACKAGE}"
    ;;
#    debian6|debian7)
#        local install_cmd='apt-get --force-yes'
#        local package="${APT_PACKAGE}"
#        eval "${install_cmd} install -y sysv-rc-conf >/dev/null 2>&1" || eval "echo ${install_cmd} fail! 1>&2;exit 1"
#    ;;
    *)
        echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac

if [ "${install_cmd}" = 'yum' -a "${para}" = 'lan' ];then
        install_cmd="yum --skip-broken --nogpgcheck --disablerepo=\* --enablerepo=${YUM_SOURCE_NAME}"
fi

local log_file="${TEMP_PATH}/YUM.log"

echo -n "Install ${package} please wait ...... "
eval "${install_cmd} install -y ${package} >${log_file} 2>&1" || local install_stat='fail'
if [ "${install_stat}" = "fail" ];then
        echo -e "${install_cmd} not available!\nview error please type: less ${log_file}" 1>&2
        exit 1
fi
echo "done."
}

create_tmp_dir () {
mkdir -p "${INSTALL_PATH}" && cd "${INSTALL_PATH}" || local mkdir_dir='fail'
if [ "${mkdir_dir}" = "fail"  ];then
        echo "mkdir ${INSTALL_PATH} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
test -d "${INSTALL_PATH}" && rm -rf "${INSTALL_PATH}"
}

download_file () {
local   url="$1"

        echo -n "Download ${url} ...... "
        wget -q "${url}"  && echo 'done.' || local download='fail'
        if [ "${download}" = "fail" ];then
                echo "fail!" 1>&2 && del_tmp
                exit 1
        fi
}

check_file () {
local file="$1"
local ex_dir=`echo "${file}"|awk -F'.tar|.tgz' '{print $1}'`
local dir="${INSTALL_PATH}/${ex_dir}"

test -f ${file} && tar xzf ${file} || eval "echo ${file} not exsit!;del_tmp;exit 1"
test -d ${dir} && cd ${dir} || eval "echo ${dir} not exsit!;del_tmp;exit 1"
echo -n "Compile ${file} please wait ...... "
}

run_cmds () {
local   cmd_log="${TEMP_PATH}/install_${PACKAGE}.log"
        test -f "${cmd_log}" && rm -f ${cmd_log}
        for cmd in "$@"
        do
                ${cmd} >> "${cmd_log}" 2>&1 || compile='fail'
                if [ "${compile}" = 'fail' ]; then
                        echo "run ${cmd} error! please type: less ${cmd_log}" 1>&2 && del_tmp
                        exit 1
                fi
        done
        echo "done."
#               cd ..
}

download_and_check () {
        download_file "${PACKAGE_URL}/${PACKAGE}"
        check_file "${PACKAGE}"
}

create_user () {
local user="$1"
local shell="$2"
case "${shell}" in
    bash)
        local user_shell='/bin/bash'
    ;;
	nologin)
        local user_shell='/sbin/nologin -M'
	;;
	ksh)
        local user_shell='/bin/ksh'
	;;
    *)
        echo "This script not support ${shell}" 1>&2
                exit 1
        ;;
esac

id "${user}" >/dev/null 2>&1 ||\
/usr/sbin/useradd "${user}" -s ${user_shell}
}

echo_bye () {
        echo "Install ${PACKAGE} complete!"
}

exit_and_clear () {
                del_tmp
                echo_bye
}

#install mysql func
set_my_cnf () {
        test ! -e /etc/my.cnf &&\
        echo "[client]
port            = 3306
socket          = /tmp/mysql.sock
[mysqld]
datadir=${DB_PATH}/mysql
basedir=/usr/local/mysql
log-error=${MYSQL_LOG_PATH}/mysql.err
pid-file=/var/run/mysqld/mysqld.pid
log-bin=${DB_PATH}/mysql/binlog/mysql-bin
relay-log=${DB_PATH}/mysql/binlog/mysqld-relay-bin
innodb_data_home_dir=${DB_PATH}/mysql/innodata
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
interactive-timeout" > /etc/my.cnf
#set default value
mysql_socket_path='/var/lib/mysql'
mkdir -p ${mysql_socket_path}
chown -R ${mysql_socket_path}
local socket_file='/var/lib/mysql/mysql.sock'
test -f "${socket_file}" && rm -f "${socket_file}"
ln -s /tmp/mysql.sock ${socket_file}
}

set_auto_run () {
    test -e /usr/local/mysql/support-files/mysql.server && cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld
    test -e /etc/rc.d/init.d/mysqld && chmod 755 /etc/rc.d/init.d/mysqld
    chkconfig --add mysqld
    chkconfig mysqld on
}

main () {
#VALUE FOR MYSQL
DB_PATH='/data'
DB_USER='mysql'
MYSQL_LOG_PATH='/var/log/mysql'

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET PACKAGE
YUM_SERVER='yum.suixingpay.local'
YUM_PACKAGE='bison ncurses-devel gcc gcc-c++ cmake'
APT_PACKAGE='build-essential'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#Install mysql 5.5.25
PACKAGE='mysql-5.5.25a.tar.gz'

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
cd ..
mkdir -p /var/run/mysqld ${DB_PATH}/mysql/{binlog,innodata} ${MYSQL_LOG_PATH}
chown -R mysql:mysql ${DB_PATH}/mysql /var/run/mysqld ${MYSQL_LOG_PATH}
chmod 700 ${DB_PATH}/mysql/{binlog,innodata} ${MYSQL_LOG_PATH}
test ! -e /etc/profile.d/mysql_env.sh && echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql_env.sh
source /etc/profile.d/mysql_env.sh
test -e  /usr/local/mysql/scripts/mysql_install_db &&\
/usr/local/mysql/scripts/mysql_install_db --basedir=/usr/local/mysql/ --datadir=${DB_PATH}/mysql --user=mysql

set_my_cnf
set_auto_run

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
