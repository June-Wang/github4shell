#!/bin/bash
#功能：建立备份文件的快照（三天内）

#需要创建快照的文件名
myfile_name=`date -d "now" +"backup_snap_%Y_%m_%d"`
#删除的快照文件名，前三天
remove_file_name=`date -d "-3 DAY" +"backup_snap_%Y_%m_%d"`

#邮件发送人
mailto='admin@mail.com'
#邮件信息临时文件
mail_content=/tmp/mail.$$
#本机ip
ip=`/sbin/ifconfig eth0|awk -F'[ ]+[a-zA-Z ]+:' '/inet addr:/ {print $2}'`

#删除临时文件
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${mail_content}"  EXIT

#挂载状态，删除快照失败时使用
my_mount=`mount -l|grep "${remove_file_name}"`
#快照源
my_source='/dev/vg_data/backup'
#从快照源获取快照路径
my_path=`echo "${my_source}"|sed -r 's|(^.*/).*|\1|'`
#创建快照的大小
source_value=`df -P|awk '/vg_data-backup/{print $3}'`
my_value=`echo "${source_value}+5120000"|bc`
my_value="${my_value}K"

#快照源不存在，退出脚本并打印告警信息
if [ ! -r ${my_source} ]; then
	echo " ${my_source} does not exist!"
	exit 1
fi

#判断创建文件是否存在，存在打印提示，不存在创建
if [ -r ${my_path}${myfile_name} ];then
        echo " ${myfile_name} has been created!"
else                
	/usr/sbin/lvcreate -s -L ${my_value} -n ${myfile_name} ${my_source} 2>>${mail_content}
fi

#如果要删除的快照存在，进行删除，否则打印提示，删除失败信息发送到邮件
if [ -r ${my_path}${remove_file_name} ]; then
        /usr/sbin/lvremove -f ${my_path}${remove_file_name} 2>>${mail_content}
else
        echo " ${my_path}${remove_file_name} does not exist!"
fi

#如果有失败信息，发送邮件
if [ -s ${mail_content} ] ;then
        echo " ${my_mount}">>${mail_content}
        cat ${mail_content}|\
        mutt -s "lvremove ERROR! ip:${ip}" -e 'set realname="Snap Cron"' -b ${mailto}
fi
