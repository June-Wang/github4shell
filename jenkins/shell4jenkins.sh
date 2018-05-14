time_now (){
    local time_now=`date -d now +"%F %T"`
    echo "${time_now}"
}

#date_now=`date -d now +"%Y%m%d"`
date_now='20180510'
id='wap-tomcat'
pro='bjf-wap'

ansible bjf-wap-A -i ~/hosts/bjf-wap.hosts -m script  -a "~/shell/ftp_download.sh ${pkg_name} ${ftp_url}/${date_now} ${ftp_user} ${ftp_passwd}"|grep -v 'stdout\"'

echo "A组"
echo "A组开始时间: "`time_now`
ansible bjf-wap-A -i ~/hosts/bjf-wap.hosts -m script  -a "~/shell/deploy_tomcat.sh ${id} ${pro} ${pkg_name}"|grep -v 'stdout\"'
echo "A组结束时间: "`time_now`

ansible bjf-wap-B -i ~/hosts/bjf-wap.hosts -m script  -a "~/shell/ftp_download.sh ${pkg_name} ${ftp_url}/${date_now} ${ftp_user} ${ftp_passwd}"|grep -v 'stdout\"'

echo "B组"
echo "B组开始时间: "`time_now`
ansible bjf-wap-B -i ~/hosts/bjf-wap.hosts -m script  -a "~/shell/deploy_tomcat.sh ${id} ${pro} ${pkg_name}"|grep -v 'stdout\"'
echo "B组结束时间: "`time_now`
