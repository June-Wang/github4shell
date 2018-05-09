#!/bin/bash
#
# This script checks if a mysql server is healthy running on localhost. It will
# return:
# "HTTP/1.x 200 OK\r" (if mysql is running smoothly)
# - OR -
# "HTTP/1.x 500 Internal Server Error\r" (else)
#
# The purpose of this script is make haproxy capable of monitoring mysql properly
#
# Edit /etc/my.conf
#[client]
#port=3306
#user=root
#password=password

MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
MYSQL_OPTS="--skip-column-names -s -A -C"
MYSQL_BIN="/usr/bin/mysql"
#CHECK_OPT='Com_show_table_status'
#CHECK_QUERY="show global status where variable_name='${CHECK_OPT}'"
CHECK_OPT='bfb'
CHECK_QUERY="SHOW DATABASES like '${CHECK_OPT}'"
return_ok()
{
    echo -e "HTTP/1.1 200 OK\r\n"
    echo -e "Content-Type: text/html\r\n"
    echo -e "Content-Length: 43\r\n"
    echo -e "<html><body>MySQL is running.</body></html>\r\n"
    exit 0
}
return_fail()
{
    echo -e "HTTP/1.1 503 Service Unavailable\r\n"
    echo -e "Content-Type: text/html\r\n"
    echo -e "Content-Length: 42\r\n"
    exit 1
}

query=`$MYSQL_BIN $MYSQL_OPTS --host=$MYSQL_HOST --port=$MYSQL_PORT -e "$CHECK_QUERY" |grep "${CHECK_OPT}"`
test -z "${query}" && return_fail
status=`echo ${query}|awk '{print $NF}'`

#if [ "$status" == '0' ]; then
if [ "$status" == ${CHECK_OPT} ]; then
        return_ok
else
                return_fail
fi
return_ok
