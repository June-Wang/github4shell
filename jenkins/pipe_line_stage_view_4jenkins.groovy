#!groovy
node {
    stage '环境变量配置'
        def javaHome = tool 'jdk1.8'
        env.PATH = "${javaHome}/bin:${env.PATH}"
        def date_now = '20180510'
        def id = 'wap-tomcat'
        def pro = 'bjf-wap'
        
    stage 'WAR包下载[A组]'
       sh "ansible bjf-wap-A -i ~/hosts/bjf-wap.hosts -m script  -a \"~/shell/ftp_download.sh ${pkg_name} ${ftp_url}/${date_now} ${ftp_user} ${ftp_passwd}\"|grep -v 'stdout\"'"

    stage '主机部署[A组]'
       sh "ansible bjf-wap-A -i ~/hosts/bjf-wap.hosts -m script  -a \"~/shell/deploy_tomcat.sh ${id} ${pro} ${pkg_name}\"|grep -v 'stdout\"'"

    stage 'WAR包下载[B组]'
       sh "ansible bjf-wap-B -i ~/hosts/bjf-wap.hosts -m script  -a \"~/shell/ftp_download.sh ${pkg_name} ${ftp_url}/${date_now} ${ftp_user} ${ftp_passwd}\"|grep -v 'stdout\"'"

    stage '主机部署[B组]'
       sh "ansible bjf-wap-B -i ~/hosts/bjf-wap.hosts -m script  -a \"~/shell/deploy_tomcat.sh ${id} ${pro} ${pkg_name}\"|grep -v 'stdout\"'"
}
