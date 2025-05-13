#!/bin/bash

[ "$1" = "" ] && echo "Usage: $0 10809 curl https://your-command.com/url" && exit 1

addr=127.0.0.1
port=$1
tmpf="/tmp/.pc$addr$port.conf"

conf="
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5 	$addr $port
"

if [ ! -f "$tmpf" ]; then
    echo "$conf" > "$tmpf"
fi

shift
proxychains -q -f "$tmpf" "$@"

