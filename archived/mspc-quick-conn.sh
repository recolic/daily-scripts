#!/bin/fish
set ip $argv[1]

set pool "
4 52.225.221.93
5 52.225.219.189
6 68.154.25.86
7 68.154.24.234
lb2 40.79.34.210
lb1 172.176.121.136

261 20.252.245.95
262 20.168.171.4
263 20.252.220.183
26l 20.252.233.54
#26l2 20.1.113.101
26l2 proxy-cdn.recolic.net:30651
"

if not string match "*.*" $ip
    if string match "*l*" $ip
        set port 8888 # lb default port
    else
        set port 22
    end
    set ip (echo $pool | grep "^$ip " | cut -d ' ' -f 2)
    if string match "*:*" $ip
        # ip contains port.. split it
        set port (echo $ip | cut -d : -f 2)
        set ip (echo $ip | cut -d : -f 1)
    end
    echo ADDR=$ip:$port
end

echo "ERROR: PASSWORD CENSORED"
sshpass -p ___ ssh -o ServerAliveInterval=3 -p $port r@$ip

