#!/bin/bash

#判断是否重复安装
es_config='/etc/elasticsearch/elasticsearch.yml'
test -f ${es_config} &&\
eval "echo ${es_config} exist!;exit 1"

#判断是否centos
test -f /usr/bin/yum ||\
eval "echo 此脚本不支持本系统!;exit 1"

file_server='http://file.server.local/soft'

file_list=(
jdk-8u231-linux-x64.rpm
install_es7.sh
elastic-stack-ca.p12
elasticsearch-7.9.1-x86_64.rpm
elastic-certificates.p12
)

#SET TEMP DIR
INSTALL_PATH="/tmp/install_$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_PATH} && rm -rf ${INSTALL_PATH}"  EXIT

test -d ${INSTALL_PATH} || mkdir -p ${INSTALL_PATH}

url="${file_server}/es"
for file in "${file_list[@]}"
do
    echo "Download ${url}/${file}"
    wget ${url}/${file} -O ${INSTALL_PATH}/${file} >/dev/null 2>&1 ||\
    eval "echo Download ${url}/${file} failure!"
done

for file in "${file_list[@]}"
do
    test -f ${INSTALL_PATH}/${file} ||\
            echo -e "${file} " > ${INSTALL_PATH}/miss.file
done

test -s ${INSTALL_PATH}/miss.file &&\
        eval "echo `cat ${INSTALL_PATH}/miss.file` not found!;exit 1"

cd ${INSTALL_PATH} &&\
        /bin/bash install_es7.sh ||\
        eval "echo path ${INSTALL_PATH} not found!;exit 1"
