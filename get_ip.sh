#!/bin/bash

ip address show|grep inet|awk '{print $NF"\t"$2}'|grep -oP '^.+\d{1,3}(\.\d{1,3}){3}'
