# insecure v2ray docker image. It's especially designed for SNI spoofing, without ANY security feature!
# for simply secure one-click script, use: https://github.com/recolic/v2ray-edit-from-233boy
# 
# sudo docker build -t recolic/insecure-v2ray .
# sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 recolic/insecure-v2ray
from ubuntu:22.04
run DEBIAN_FRONTEND="noninteractive" apt update && DEBIAN_FRONTEND="noninteractive" apt install v2ray curl -y

copy . /app
run cd /app/quickngx && bash quick-nginx-insecure.sh

run apt clean
run rm -rf /var/lib/apt/lists/*

cmd ["bash", "/app/entry.sh"]

