#!/bin/bash

#sudo systemd-cat -t autostart-ss sslocal -s 127.0.0.1 -p 12948 -l 1080 -k KEY_HERE___ -d start
#sudo systemd-cat -t autostart-ss-kcp /home/recolic/kcptun/kcpd-ss.sh &

# sudo systemd-cat -t autostart-ss sslocal -s base.tw1.recolic.net -p 25551 -k KEY_HERE___ -d start
# sudo systemd-cat -t autostart-ss sslocal -c /home/recolic/Documents/ovpn/tw1.recolic.ssr.json -d start
# nohup sslocal -c /home/recolic/Documents/ovpn/us6.recolic.ssr.json > /dev/null 2>&1 & disown

# SSR fucked. Use v2ray systemd service now
# nohup sslocal -c /home/recolic/Documents/ovpn/tw1.recolic.ssr.json > /dev/null 2>&1 & disown

# IPLC!!!
# sudo systemd-cat -t autostart-ss sslocal -s base.cnjp1.recolic.cc -p 25551 -k KEY_HERE___ -m aes-128-cfb -l 1080 -b 0.0.0.0 --fast-open -d start


