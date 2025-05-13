#!/bin/bash

uname -r | grep -E '^4\.(1[^\.]|9)' > /dev/null
(( $? == 1 )) && echo 'Linux kernel version must >= 4.9' && exit 1

[[ `whoami` != root ]] && echo 'You must be root' && exit 1

lsmod | grep bbr > /dev/null
(( $? == 1 )) &&
    modprobe tcp_bbr &&
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf &&
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf &&
sysctl -p

sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control

sysctl net.ipv4.tcp_congestion_control | grep bbr > /dev/null && echo 'Success.' || echo 'Failed.'
