#!/bin/bash

usage () {
        echo -en "USAGE: $0 [host list] or $0 [template] [host list]\nFor example: $0 host.template host.list(Field : [IP])\n" 1>&2
        exit 1
}

if [ $# -gt 2 ];then
        usage
        exit 1
fi

case "$#" in
        2)
                template=$1
                host_list=$2
        ;;
        *)
                usage
        ;;
esac

if [ ! -f "${template}" ];then
        echo "template : ${template} not exist!" 1>&2
        exit 1
fi

if [ ! -f "${host_list}" ];then
        echo "host list : ${host_list} not exist!" 1>&2
        exit 1
fi

backup_path='/usr/local/nagios/backup'
test -d ${backup_path} || mkdir -p ${backup_path}

nagios_cfg_path='/usr/local/nagios/etc/servers'
test -d ${nagios_cfg_path} && cd ${nagios_cfg_path}

time_now=`date -d now +"%Y-%m-%d_%H-%M-%S"`
tar czf ${backup_path}/servers_${time_now}.tar.gz ./*

#path='/usr/local/nagios/etc/new_host'
#test -d ${path} || exit 1 && cd ${path}

cd -
cat ${host_list}|\
while read ip
do
        echo "${ip}"|grep -oP '^\d{1,3}(\.\d{1,3}){3}$' >/dev/null 2>&1 || Field='not ip'
        if [ "${Field}" = 'not ip' ];then 
                echo "${ip} not ip!" 1>&2
                exit 1
        fi
                find ../servers/ -type f -name "*${ip}\.cfg"|\
				sed -r 's/.*\/(.*)-.*$/& \1/'|\
                while read file hostname
                do
                        test -f ${file} && sed "s/HOST_NAME/${hostname}/g" ${template} >> ${file}
                done
done
