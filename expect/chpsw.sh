#!/bin/bash

usage () {
        echo "USAGE: $0 [host list:format ip user passwd]" 1>&2
        exit 1
}

sc_file_name=`basename $0`

[ "$#" -ne 1 ] && usage "${sc_file_name}"

host_list=$1

if [ ! -f "${host_list}" ];then
        echo "${host_list} not exist!"  1>&2
        exit 1
fi

path=`dirname "$0"`
exp_file_name="${path}/chpsw.exp"

if [ ! -f "${exp_file_name}" ];then
        echo "${exp_file_name} not exist!" 1>&2
        exit 1
else
        chmod +x ${exp_file_name}
fi

if [ -d "${path}" ]; then
    cd ${path}
else
        path='.'
fi

#chk mkpasswd
#which mkpasswd >/dev/null 2>&1 || chk='fail'

#chk expect
which expect >/dev/null 2>&1 || chk='fail'

if [ "${chk}" = 'fail' ];then
        echo "mkpasswd not find! please install expect!" 1>&2
        exit 1
fi

mydate=`date -d  "NOW" +"%Y/%m/%d"`
timeout=5
log_path="./log/${sc_file_name}/${mydate}"
#info_path="./info/${sc_file_name}"

pipefile=/tmp/fifo.$$
mkfifo $pipefile
exec 3<>$pipefile

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${pipefile}"  EXIT

Threshold=12
seq ${Threshold} >&3

mkdir -p ${log_path}
#mkdir -p ${info_path}

now=`date -d now +"%Y%m%d%H%M%S"`
my_date=`date -d now +"%Y-%m-%d %H:%M:%S"`
log_file="${log_path}/chpwd.log"
chmod 600 ${log_file}

grep -Ev "^#"  ${host_list}|
while read host user password
do
        read -u 3
#        new_password=`echo -n $RANDOM|md5sum|head -c 20`
        new_password=`mkpasswd -l 25 -d 3 -C 5 -s 5|grep -o '.'|grep -Ev '\$|\"|\&|\\`|\;|\^|'\'''|awk 'BEGIN{ORS=""}NR<=14{print}END{print "\n"}'`
#       md5_password=`echo ${new_password}|md5sum`
#       base64_pawwword=`echo ${new_password}|base64`
        (
                ./chpsw.exp ${host} ${user} ${password} ${timeout} ${new_password}\
                >${log_path}/${host}.log 2>&1 && cmd_status='ok'
                if [ "${cmd_status}" = "ok" ];then
                        echo -en "${host}\t${user}\t${new_password}\n" > new.list  #.${now}
                        echo -en "${my_date}\t${host}\t${user}\t ${password}\tchanged to\t${new_password}\n" >> ${log_file}
                        #chmod 600 "new.list.${now}"
                        chmod 600 "new.list"
                else
                        echo -en "${my_date}\t${host}\t${user}\t change password fail!\n" >> ${log_file}
                fi
                echo >&3
        )&
done

wait
exec 3>&-
