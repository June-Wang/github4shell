#!/bin/bash

awk -F: '$3>=500 && $NF!="/sbin/nologin" || $1=="root"{print $1,$6}' /etc/passwd|\
while read user path
do
        his_file="$path/.bash_history"
        if [ -s "${his_file}" ];then
                count=`cat ${his_file}|wc -l`
                cat ${his_file}|\
                while read line
                do
                        str=`echo "${line}"|sed -nr '/^#[0-9]{10}$/p'`
                        if [ -n "${str}" ];then
                                my_time=`echo "${line}"|sed 's/^#//'`
                                my_date=`date -d "1970-01-01 UTC ${my_time} sec" "+%Y-%m-%d %T "`
                                echo -en "${my_date}"
                        else
                                echo "${line}"
                        fi
                done |sort|\
                        while read cmd
                        do
                                 logger -t history[$$] -p local4.debug "${user} ${cmd}"
                        done
        sed -i "1,${count}d" ${his_file}
        fi
done
