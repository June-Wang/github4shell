#!/bin/bash

path='/usr/local/bin'
test -d ${path} &&\
wget https://raw.githubusercontent.com/June-Wang/github4shell/master/netstat_influx.sh -O ${path}/netstat_influx.sh &&\
test -f ${path}/netstat_influx.sh && chmod +x ${path}/netstat_influx.sh && ls -lth ${path}/netstat_influx.sh

config='/etc/telegraf/telegraf.conf'
test -f ${config} || exit 1

grep 'inputs.exec' ${config} >/dev/null 2>&1 ||\
echo '[[outputs.graylog]]
  ## UDP endpoint for your graylog instance(s).
  servers = ["192.168.1.176:12201","192.168.1.177:12201","192.168.1.108:12201","192.168.1.129:12201"]
[[inputs.exec]]
  commands = ["/bin/bash /usr/local/bin/netstat_influx.sh eth0"]
  timeout = "30s"
  data_format = "influx"' >> ${config}

service telegraf restart
