#!/bin/bash

/sbin/ip addr list|grep -B1 inet|grep -Ev '00:00:00:00:00:00|127.0.0.1|255|^--|inet6'
