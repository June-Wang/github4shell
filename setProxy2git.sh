#!/bin/bash

git_cmd='git config --global'
proxy_host='proxy.server.local'
proxy_port='8087'

for para in https.proxy core.gitproxy http.proxy
do
	eval "${git_cmd} ${para} ${proxy_host}:${proxy_port}"
done

git config --global http.sslVerify false
