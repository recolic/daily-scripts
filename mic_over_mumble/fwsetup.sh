#!/bin/bash

sudo iptables -I INPUT -p tcp -m tcp --dport 64738 -j ACCEPT
echo 'Please connect to THISMACHINE:64738 on your phone.'
