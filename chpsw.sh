#!/bin/bash

USER="$1"

passwd=`openssl rand -base64 11|grep -oE '^.{10}'|head -n 1`

ip=`ip address show|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$|\.0$'|head -n1`

echo ${USER}:${passwd}|chpasswd

echo -en "${ip}\t${USER}\t${passwd}\n"
