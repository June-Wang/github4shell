#!groovy
node {
    stage '环境变量配置'
        def javaHome = tool 'jdk1.8'
        env.PATH = "${javaHome}/bin:${env.PATH}"
        
        def id = 'wap-tomcat'
        def pro = 'bjf-wap'
        
    stage 'WAR包下载[A组]'
       sh "ansible bjf-wap-A -i ~/hosts/bjf-wap.hosts -m raw  -a \"curl -s http://yum.server.local/deploy/shell/ftp_download.sh|/bin/bash -s \"${pkg_name}\" \"${ftp_url}\" \"${ftp_user}\" \"${ftp_passwd}\"\"|grep -v 'stdout\"'"

    stage '主机部署[A组]'
       sh "ansible bjf-wap-A -i ~/hosts/bjf-wap.hosts -m raw  -a \"curl -s http://yum.server.local/deploy/shell/deploy_tomcat.sh|/bin/bash -s \"${id}\" \"${pro}\" \"${pkg_name}\"\"|grep -v 'stdout\"'"

    stage 'WAR包下载[B组]'
       sh "ansible bjf-wap-B -i ~/hosts/bjf-wap.hosts -m raw  -a \"curl -s http://yum.server.local/deploy/shell/ftp_download.sh|/bin/bash -s \"${pkg_name}\" \"${ftp_url}\" \"${ftp_user}\" \"${ftp_passwd}\"\"|grep -v 'stdout\"'"

    stage '主机部署[B组]'
       sh "ansible bjf-wap-B -i ~/hosts/bjf-wap.hosts -m raw  -a \"curl -s http://yum.server.local/deploy/shell/deploy_tomcat.sh|/bin/bash -s \"${id}\" \"${pro}\" \"${pkg_name}\"\"|grep -v 'stdout\"'"
}
