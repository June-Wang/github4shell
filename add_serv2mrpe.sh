#!/bin/bash

#test path
test -d /etc/check_mk/ || mkdir -p /etc/check_mk/

#test file
mrpe_file='/etc/check_mk/mrpe.cfg'
test -f ${mrpe_file} || touch ${mrpe_file}

#add serv
netstat -lnp|awk '$(NF-1)~/LISTEN/ && $NF~/java/{print $4}'|\
grep -v '127.0.0.1'|grep -oP '\d+$'|\
while read serv_port
do
        grep "check_tcp_${serv_port}" ${mrpe_file} >/dev/null 2>&1 ||stat='0'
        if [ "${stat}" == '0' ];then
                echo "check_tcp_${serv_port} /usr/local/nagios/libexec/check_tcp -w 2 -c 3 -t 4 -p ${serv_port}" >> ${mrpe_file}
                echo "add ${serv_port} to mrpe!"
        else
                echo "${serv_port} has been added to mrpe!"
        fi
done
