#!/bin/bash

docker ps|awk 'NR>1{print $NF}'|xargs -r -i echo "check_docker_container_status_{} /usr/local/nagios-plugins/check_docker_container_status.py -C '{}' -t3"
