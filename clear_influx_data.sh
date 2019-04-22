#!/bin/bash

influx_cmd='/usr/bin/influx -host localhost'
${influx_cmd} -execute 'show databases;' -format column|\
grep -Ev '^name|---|_internal'|\
while read database
do
    ${influx_cmd} -execute 'show MEASUREMENTS;' -database ${database} -format column|\
grep -Ev '^name|---'|xargs -r -i echo "${database} {}"
done|\
while read database measurement
do
    ${influx_cmd} -execute "delete from ${measurement} where time < now() -30d;" -database ${database} -format column
done
