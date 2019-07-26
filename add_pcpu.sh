#!/bin/bash

path='/usr/local/bin'
test -d ${path} &&\
wget https://raw.githubusercontent.com/June-Wang/github4shell/master/pcpu_telegraf.sh -O ${path}/pcpu_telegraf.sh &&\
test -f ${path}/pcpu_telegraf.sh && chmod +x ${path}/pcpu_telegraf.sh && ls -lth ${path}/pcpu_telegraf.sh

config='/etc/telegraf/telegraf.conf'
test -f ${config} || exit 1

grep 'inputs.exec' ${config} ||\
echo '
# Send telegraf metrics to graylog(s)
[[outputs.graylog]]
  ## UDP endpoint for your graylog instance(s).
  servers = ["10.0.0.16:12201", "10.0.0.17:12201","10.0.0.18:12201","10.0.0.19:12201"]
[[inputs.exec]]
  commands = ["/bin/bash /usr/local/bin/pcpu_telegraf.sh eth0"]
  timeout = "20s"
  data_format = "influx"' >> ${config}

service telegraf restart
