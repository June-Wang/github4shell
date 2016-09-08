#!/bin/bash

sed -i '/net.ipv4.ip_forward/s/0/1/' /etc/sysctl.conf

sysctl -p

iptables -I INPUT -p tcp --dport 1194 -m comment --comment "openvpn" -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE

service iptables save
