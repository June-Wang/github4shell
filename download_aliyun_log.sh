#!/bin/bash

ago=`date -d '-1min' +"%H_%M"`
now=`date -d 'now' +"%H_%M"`

/usr/local/bin/aliyunlog log pull_log_dump \
--project_name="finance-slb-log" --logstore_name="prod-finance" \
--from_time="1 min ago" --to_time="now" --file_path="/data/aliyunlog/dump_${now}_{}.log"

rm -f /data/aliyunlog/dump_${ago}*.log
