# secure v2ray docker image, with vless
# 
# sudo docker build -t recolic/secure-v2ray .
# WARNING: If redirecting 443 to other port, you must pass 80 instead, for TLS cert verification.
# sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 -e DOMAIN=cheap.my-domain.com -e SECRET_UUID=ec0cba37-926d-4386-b8c1-0a71c06bcebd recolic/secure-v2ray
# sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 -e DOMAIN=cheap.my-domain.com -e SECRET_UUID=ec0cba37-926d-4386-b8c1-0a71c06bcebd -e PROXY_PASS=https://azure.microsoft.com/zh-cn recolic/secure-v2ray
from ubuntu:22.04
run DEBIAN_FRONTEND="noninteractive" apt update && DEBIAN_FRONTEND="noninteractive" apt install v2ray curl wget -y

copy . /app

run wget "https://github.com/caddyserver/caddy/releases/download/v1.0.4/caddy_v1.0.4_linux_amd64.tar.gz" -O /tmp/caddy1.tar.gz && tar xvzf /tmp/caddy1.tar.gz
run mv caddy /usr/bin/caddy1
    
#run wget "https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=65570995587275" -O /usr/bin/caddy2
#run chmod +x /usr/bin/caddy2

run apt clean
run rm -rf /var/lib/apt/lists/*

cmd ["bash", "/app/entry.sh"]

