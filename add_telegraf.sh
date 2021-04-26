#!/bin/bash

yum_server='yum.server.local'

shells=(
pcpu_telegraf.sh
netstat_telegraf.sh
ip_port_telegraf.sh
)

for shell in "${shells[@]}"
do
    sudo wget http://${yum_server}/${shell} -O /usr/local/bin/${shell}
    test -f /usr/local/bin/${shell} && sudo chmod +x /usr/local/bin/${shell}
done
 
telegraf_config='/etc/telegraf/telegraf.conf'

grep 'pcpu_telegraf' ${telegraf_config} >/dev/null 2>&1||\
echo '[[inputs.exec]]
  commands = ["/bin/bash /usr/local/bin/pcpu_telegraf.sh","/bin/bash /usr/local/bin/netstat_telegraf.sh","/bin/bash /usr/local/bin/ip_port_telegraf.sh"]
  timeout = "20s"
  data_format = "influx"' |sudo tee -a ${telegraf_config}
  
sudo service telegraf restart
