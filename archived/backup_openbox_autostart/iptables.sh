#!/bin/bash

sudo iptables-restore < /etc/iptables/iptables.rules
sudo ip6tables-restore < /etc/iptables/ip6tables.rules
