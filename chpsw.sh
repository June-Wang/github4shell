#!/bin/bash

USER='root'

passwd=`openssl rand -base64 11|grep -oE '^.{10}'|head -n 1`

ip=`ip address show|awk '/inet/{print $2}'|grep -oP '^.+\d{1,3}(\.\d{1,3}){3}'|grep -Ev '127'|head -n1`

echo ${USER}:${passwd}|chpasswd

echo -en "${ip}\t${USER}\t${passwd}\n"
