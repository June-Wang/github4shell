#!/bin/bash

user_id="$1"
user_id="cw"

id ${user_id} ||\
eval "echo ${user_id} not found!;exit 1"

su - ${user_id} -c "/usr/bin/ssh-keygen -q -t rsa -f /home/${user_id}/.ssh/id_rsa -N ''"
