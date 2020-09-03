#!/bin/bash

yum_server='192.168.1.1'
telegraf_config='/etc/telegraf/telegraf.conf'

test -f ${telegraf_config} && exit 0

file='telegraf-1.15.2-1.x86_64.rpm'
tmp="/tmp/${file}"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

wget http://${yum_server}/tools/pcpu_telegraf.sh -O /usr/local/bin/pcpu_telegraf.sh &&
chmod +x /usr/local/bin/pcpu_telegraf.sh

wget http://${yum_server}/tools/${file} -O ${tmp}
rpm -ivh ${tmp}

echo '[global_tags]
  server = "IP_ADDR"
  host_name = "HOST_NAME"
  # dc = "us-east-1" # will tag all metrics with dc=us-east-1
  # rack = "1a"
  ## Environment variables can be used as tags, and throughout the config file
  # user = "$USER"
[agent]
  interval = "30s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "30s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "aufs", "squashfs"]
[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
[[inputs.procstat]]
    pattern = "root|bin|daemon|adm"
[[inputs.exec]]
  commands = ["/bin/bash /usr/local/bin/pcpu_telegraf.sh eth0"]
  timeout = "20s"
  data_format = "influx"
# Send telegraf metrics to graylog(s)
[[outputs.graylog]]
  ## UDP endpoint for your graylog instance(s).
  servers = ["192.168.1.2:12201","192.168.1.3:12201","192.168.1.4:12201"]' > ${telegraf_config}

IP=`/sbin/ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
HOSTNAME=`hostname`

sed -r -i "s|IP_ADDR|${IP}|;s|HOST_NAME|${HOSTNAME}|" ${telegraf_config}

pattern=`awk -F':' 'BEGIN{ORS="|"}{print $1}' /etc/passwd|sed 's/.$//;s/-/|/g'`
test -f ${telegraf_config} &&\
echo "${pattern}"|xargs -r -i sed -r -i 's/pattern = .*$/pattern = \"{}\"/g' ${telegraf_config}
systemctl start telegraf
