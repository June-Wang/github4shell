#!/bin/bash

id="$1"
pro="$2"
pkg_name="$3"

check_cmd () {
which lftp >/dev/null 2>&1 ||\
eval "echo lftp 命令未找到!;exit 1"
}

show_env () {
echo '环境变量'
env|grep -E 'USER|JAVA|PATH|HOME|CLASSPATH|PWD'|sort
}

stop_tomcat () {
echo "关闭tomcat中..."

test -d ~/${id} ||\
eval "echo 项目路径 ~/${id} 不存在!;exit 1"

test -d ~/${id}/bin ||\
eval "echo ~/${id}/bin 路径不存在!;exit 1"

cd ~/${id}/bin 

test -f ./shutdown.sh ||\
eval "echo 未找到 shutdown.sh 文件!;exit 1" &&\
ls -lth ./shutdown.sh

nohup  ./shutdown.sh >/dev/null 2>&1

pid=`ps -eo user,pid,args |grep -E "${id}"|grep java|grep -v grep|awk '{print $2}'`
test -n "${pid}" && kill ${pid}
ps -eo user,pid,args |grep -E "${id}"|grep java|grep -v grep
echo "tomcat 已关闭!"
}

backup_tomcat (){
local app_path=~/latest/${pro}/${id}
echo "开始备份${app_path}"
local time_now=`date -d now +"%F_%H-%M-%S"`
local bak_path=~/archive/${pro}/${id}_${time_now}
test -d ~/latest/${pro}/${id} ||\
eval "echo 目标文件夹~/latest/${pro}/${id} 不存在!;exit 1"

test -d ~/archive/${pro} || mkdir -p ~/archive/${pro}
test -d ~/archive/${pro} ||\
eval "echo ~/archive/${pro} 文件夹无法创建!;exit 1"

mv ~/latest/${pro}/${id} ${bak_path} ||\
eval "echo 备份 ~/latest/${pro}/${id} 失败!;exit 1"
echo "${app_path}备份完毕!"
echo "备份路径${bak_path}"
}

deploy_tomcat (){
local app_path=~/latest/${pro}/${id}
local file="/tmp/${pkg_name}"
echo "开始部署${file}"
test -f ${file} ||\
eval "echo 部署文件${file} 不存在!;exit 1"
unzip -d "${app_path}" "${file}" >/dev/null 2>&1 ||\
eval "echo 解压文件${file}失败!;exit 1"
echo "${pkg_name}部署完毕!"
test -f ${file} && rm -f "${file}" &&\
echo "${file}已删除!"
}

start_tomcat (){
echo "开始启动tomcat"
cd ~/${id}/bin && nohup ./startup.sh >/dev/null 2>&1
ps -eo user,pid,args|grep java|grep -v grep|grep "${id}" &&\
eval "echo tomcat启动成功!" ||\
eval "echo tomcat启动失败!;exit 1"
}

rm_bakcup () {
echo "清除备份文件"
test -d ~/archive/${pro} &&\
find ~/archive/${pro} -maxdepth 1 -mindepth 1 -type d|sort -r|sed '1,5d'|xargs -r -i rm -rf '{}'
}

main () {
check_cmd
echo "开始部署${pro}"
show_env
stop_tomcat
sleep 2s
backup_tomcat
deploy_tomcat
start_tomcat
rm_bakcup
echo "${pro}部署完毕!"
}

main
