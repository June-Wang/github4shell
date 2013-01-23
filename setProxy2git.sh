#!/bin/bash

git_cmd='git config --global'
proxy_host='192.168.29.237'
proxy_port='8087'

for para in https.proxy core.gitproxy http.proxy
do
	eval "${git_cmd} ${para} ${proxy_host}:${proxy_port}"
done

git config --global http.sslVerify false
