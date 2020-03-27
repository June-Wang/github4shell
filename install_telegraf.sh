#!/bin/bash

url='https://dl.influxdata.com/telegraf/releases/telegraf_1.10.2-1_amd64.deb'
file_name=`echo ${url}|awk -F'/' '{print $NF}'`
tmp="/tmp/${file_name}"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

wget ${url} -O ${tmp} ||\
eval "echo download $url fail!;exit 1"

test -f ${tmp} ||\
eval "echo ${tmp} not found!;exit 1"

sudo dpkg -i /tmp/${file_name} &&\
echo '[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false
[[outputs.influxdb]]
  urls = ["http://172.26.0.120:8086"]
  database = "telegraf"
  username = "telegraf"
  password = "Ab2016"
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
    pattern = "perl|sh|python|mq|java|nginx|daemon|root|sysop|ubuntu|telegraf|mysql|mongodb|redis"
    #user = "nginx|daemon|root|sysop|ubuntu|telegraf|mysql"' > /etc/telegraf/telegraf.conf

config='/etc/telegraf/telegraf.conf'
test -f ${config} &&\
sed -r -i 's/pattern =.*/pattern = "docker|container|cloudmonitor|consul|bash|sh|perl|AliYunDun|mq|python|java|nginx|daemon|root|sysop|ubuntu|telegraf|mysql|mongo|redis"/' ${config} &&\
sed -r -i 's/user =(.*)/#user =\1/' ${config}
sed -r -i 's/interval = "10s"/interval = "30s"/' ${config}
service telegraf restart
