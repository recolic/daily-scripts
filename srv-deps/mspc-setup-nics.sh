#!/bin/bash

# setup TPM for devbox
mkdir -p /extradisk/swtpm/mytpm
nohup bash -c 'cd /extradisk/swtpm ; while true; do swtpm socket --tpm2 --tpmstate dir=./mytpm --ctrl type=unixio,path=./mytpm.sock; done' & disown

realnic=eno2

echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 0 > /sys/devices/virtual/net/br0/bridge/multicast_querier
echo 0 > /sys/devices/virtual/net/br0/bridge/multicast_snooping

ip tuntap add vnic3 mode tap
ip tuntap add vnic2 mode tap
ip tuntap add vnic1 mode tap
ip tuntap add vnic0 mode tap
ip l add br0 type bridge

ip l set vnic3 master br0
ip l set vnic2 master br0
ip l set vnic1 master br0
ip l set vnic0 master br0
ip l set $realnic master br0

ip l set vnic3 up
ip l set vnic2 up
ip l set vnic1 up
ip l set vnic0 up
ip l set br0 up
ip l set $realnic up
dhcpcd br0 # --nohook resolv.conf # Using openvpn to provide DNS

echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 0 > /sys/devices/virtual/net/br0/bridge/multicast_querier
echo 0 > /sys/devices/virtual/net/br0/bridge/multicast_snooping

