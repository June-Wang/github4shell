#!/bin/bash

ip -4 addr show|grep inet|awk '{print $NF}'|\
while read dev
do
	info=`ip addr list|grep -A3 "${dev}"`
	ip=`echo ${info}|grep inet|grep -oP '\d{1,3}(\.\d{1,3}){3}'|head -n1`
	mac=`echo ${info}|grep link|grep -oP '\w{2}(:\w{2}){5}'|head -n1`
	echo -en "${dev}\t${ip}\t${mac}\n"
done|\
grep -Ev '127.0.0.1'
