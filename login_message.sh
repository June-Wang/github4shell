local yum_server='yum.suixingpay.local'
echo "Install jdk run :
> wget http://${yum_server}/shell/install_jdk.sh
> /bin/bash install_jdk.sh -v [1.5|1.6|1.7] -p [x86|x64]
Install tomcat run :
> wget http://${yum_server}/shell/install_tomcat.sh
> /bin/bash install_tomcat.sh -v [6|7]
"
