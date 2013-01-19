#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage () {
        echo -en "USAGE: $0 -w 20 -c 10\n" 1>&2
        exit ${STATE_WARNING}
}

check_para () {
local para="$1"
echo "${para}"|\
grep -E '^[0-9]+$' >/dev/null 2>&1 ||\
eval "echo Error parameters: ${para} . Please enter the number. 1>&2;exit ${STATE_WARNING}"
}

while getopts w:c: opt
do
        case "$opt" in
        w) 
                check_para "$OPTARG"
                warning="$OPTARG"
        ;;
        c) 
                check_para "$OPTARG"
                critical="$OPTARG"
        ;;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${warning}" -o -z "${critical}" ];then
        usage
fi

WARNING=`echo "${warning}/1"|bc`
CRITICAL=`echo "${critical}/1"|bc`

log_path="/var/log/cpu_utilization"

log_name=`date -d "now" +"%F"`
log="${log_path}/${log_name}.log"

rm_name=`date -d "-15 day" +"%F"`
rm_log="${log_path}/${rm_name}.log"

test -e ${rm_log} && rm -f ${rm_log}
test -d ${log_path} || mkdir -p ${log_path}
echo `date -d "now" +"%F %T"` >> ${log}

cpu_utilization=`ps -eo pcpu,args|\
awk '{str="";for (i=2;i<=NF;i++) str=str" "$i;item[str]+=$1}END{for (x in item) if (item[x]>0) print item[x],x}'|\
sort -nr|\
tee -a ${log}|\
awk '{sum+=$1}END{print sum}'`

num=`echo "(100-${cpu_utilization})/1"|bc`

message () {
        echo "CPU utilization is $1: ${cpu_utilization}% | CPU_utilization=${cpu_utilization};$[100-${WARNING}];$[100-${CRITICAL}];0;120"
}
if [ ${num} -le ${CRITICAL} ];then
        message CRITICAL
        exit ${STATE_CRITICAL}
fi

if [ ${num} -le ${WARNING} ];then
        message WARNING
        exit ${STATE_WARNING}
fi

message OK
exit ${STATE_OK}
