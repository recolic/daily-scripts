# secure v2ray docker image, with vless
# 
# sudo docker build -t recolic/secure-v2ray .
# sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 -e DOMAIN=cheap.my-domain.com -e SECRET_UUID=ec0cba37-926d-4386-b8c1-0a71c06bcebd recolic/secure-v2ray
# sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 -e DOMAIN=cheap.my-domain.com -e SECRET_UUID=ec0cba37-926d-4386-b8c1-0a71c06bcebd -e PROXY_PASS=https://azure.microsoft.com/zh-cn recolic/secure-v2ray
from ubuntu:22.04
run echo TODO unfinished && false
run DEBIAN_FRONTEND="noninteractive" apt update && DEBIAN_FRONTEND="noninteractive" apt install v2ray curl caddy wget -y

copy . /app
#run cd /app/quickngx && bash quick-nginx-insecure.sh

run wget "https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=65570995587275" -O /usr/bin/caddyserver
run chmod +x /usr/bin/caddyserver

run apt clean
run rm -rf /var/lib/apt/lists/*

cmd ["bash", "/app/entry.sh"]

