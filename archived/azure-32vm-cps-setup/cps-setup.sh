
function setup () {
curl https://recolic.net/setup/_setup.sh | bash

#i=$(hostname | cut -d - -f 3)
#curl 'https://recolic.cc/setup/deploy-frpc' | port=3065$i bash
curl https://recolic.cc/tmp/ubuntu-enable-root.sh | bash

wget https://recolic.net/tmp/cps.linux -O /usr/bin/cps
chmod +x /usr/bin/cps

echo "*   soft    nofile  1048575 
*   hard    nofile  1048575" >> /etc/security/limits.conf

echo "#!/bin/bash
sysctl -w net.ipv4.tcp_tw_reuse=1  # TIME_WAIT work-around 
sysctl -w net.ipv4.ip_local_port_range="10000 60000"  # ephemeral ports increased 
iptables -t raw -I OUTPUT -j NOTRACK  # disable connection tracking 
iptables -t raw -I PREROUTING -j NOTRACK  # disable connection tracking 
sysctl -w net.ipv4.tcp_syncookies=0 
sysctl -w net.ipv4.tcp_max_syn_backlog=2048 
sysctl -w net.ipv4.conf.all.rp_filter=0 
sysctl -w fs.file-max=1048576 
sysctl -w net.ipv4.tcp_fin_timeout=5 #<--- decreases the FIN_WAIT2 time so CPS server can recycle ports faster 
" > /etc/rc.local
bash /etc/rc.local
}

function server () {
    #ulimit -n -S 1000000
    #ulimit -n | grep 1000000 || ! echo "FAIL! wrong ulimit" || exit 1
    #cps -s -r 16 0.0.0.0,9900
    fish -c "ulimit -n -S 1000000 ; ulimit -n | grep 1000000 ; or exit 1 ;     while true; cps -s -r 16 0.0.0.0,9900 ; sleep 1 ; end"
}
function client () {
    #ulimit -n -S 1000000
    #ulimit -n | grep 1000000 || ! echo "FAIL! wrong ulimit" || exit 1
    echo "CONN $ip"
    fish -c "ulimit -n -S 1000000 ; ulimit -n | grep 1000000 ; or exit 1 ;     while true; cps -c -wt 30 -t 150 -r 16 0.0.0.0,0,$ip,9900,100,100,0,1 ; sleep 1 ; end"
}

"$func"


