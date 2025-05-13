#!/bin/bash

systemd-cat -t autostart-kcp echo 'Starting kcptun...'
cd /home/recolic/kcptun
sudo ./kcptun_guard.py &
