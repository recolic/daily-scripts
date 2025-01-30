#!/bin/bash
ps -aux | grep -v 'grep ssh' | grep 'rproxy@proxy.recolic.net' && echo 'Already listening...' && exit 0
sshpass -p __placeholder_password__ ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -fNR 0.0.0.0:25561:localhost:22 rproxy@proxy.recolic.net

