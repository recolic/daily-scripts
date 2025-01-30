# ip=$(curl https://api.ipify.org -4) || ip=_YOUR_IP_ADDR_

domain="$DOMAIN"
uuid="$SECRET_UUID"
pp="$PROXY_PASS"

[[ $domain = "" ]] || [[ $uuid = "" ]] && echo "ERROR: DOMAIN and SECRET_UUID must be set" && exit 1
[[ $pp = "" ]] && pp=https://localhost:8964 # redirect to random invalid port

# populate config
sed -i "s/11111111-7b5d-44a1-bb69-6e100bc0083f/$uuid/g" /app/naive-vless-server.json

echo "
$domain {
    gzip
timeouts none
    proxy / $pp {
        except /teams
    }
    proxy /teams 127.0.0.1:10000 {
        without /teams
        websocket
    }
}
" > /tmp/caddyfile_v1

echo "
{
    encode gzip
	handle_path /teams {
		reverse_proxy /teams 127.0.0.1:10000
	}
    reverse_proxy $pp
    # TODO: timeouts none
}
" > /tmp/caddyfile_v2

echo "
Link:
    vless://$uuid@$domain:443?path=%2Fteams&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#PROXY_NODE

(please modify the port if you redirect it to something else)
"

# nginx # background
# caddy2 start --config /tmp/caddyfile_v2 # background
caddy1  -conf /tmp/caddyfile_v1 -email stupid$RANDOM@shit$RANDOM.com -agree &
pidc=$!
v2ray -config /app/naive-vless-server.json &
pidv=$!

while true; do
    sleep 30
    ps -p $pidc > /dev/null || ! echo "caddy is dead" || break
    ps -p $pidv > /dev/null || ! echo "v2ray is dead" || break
done
