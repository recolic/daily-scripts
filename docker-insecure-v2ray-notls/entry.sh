ip=$(curl https://api.ipify.org -4) || ip=_YOUR_IP_ADDR_

echo "
Link: vless://11111111-7b5d-44a1-bb69-6e100bc0083f@$ip:443?path=%2Fteams&security=tls&encryption=none&host=any-domain.apple.com&type=ws&sni=any-domain.microsoft.com#INSECURE_NODE
"

nginx # background
v2ray -config /app/naive-vless-server.json
