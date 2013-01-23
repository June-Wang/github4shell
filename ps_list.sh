#!/bin/bash

usage (){
        echo -en "Usage: $0 -u [LOCAL USER]\nFor example:\t$0 -u posp\n" 1>&2
        exit 1
}

uid=`id -g`
if [ ${uid} -ne 0 ];then
	echo "only root can be execute this script!" 1>&2
	exit 1
fi

while getopts spu opt
do
        case "$opt" in
#        u)
#       check_user "$OPTARG" && sort_cmd="grep $OPTARG" ||\
#       eval "echo User: $OPTARG not exist! 1>&2;exit 1"
        u) sort_cmd='sort -k3';;
        p) sort_cmd='sort -nk2';;
        s) sort_cmd='sort -k1';;
        *) usage;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -ne 0 ] && usage

test -z "${sort_cmd}" && sort_cmd='sort -nk2'

format='%-20s%-15s%-15s%-15s'
printf "${format}\n" "SERVICE" "PID" "USER" "Socket/Port"
netstat -nlptu|\
awk '/^[tcp|udp]/ && $NF!="-" && $NF~/^[0-9]+/{sub(/^.*:/,"",$4);sub(/\//," ",$NF);print $NF,$1":"$4}'|\
sort -u|\
while read pid service port
do
        puser=`ps -o user --no-heading -p ${pid}`
        printf "${format}\n" "${service}" "${pid}"  "${puser}" "${port}"
done|\
eval ${sort_cmd}
