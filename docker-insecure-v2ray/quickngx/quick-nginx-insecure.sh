#!/bin/bash
# Usage: upload this dir to server, and start this sh
#        rsync -avz . user@remote:~/quickngx

# tmp_http_ngconf=https://recolic.net/tmp/nginx.conf
# tmp_http_fakecrt=https://recolic.net/tmp/fullchain
# tmp_http_fakecrt_k=https://recolic.net/tmp/cert.key
# use_fakecrt=1 # insecure but easier

export DEBIAN_FRONTEND="noninteractive"
apt update
apt install nginx-light -y
systemctl disable nginx --now

cp fullchain.cer dummy.key /etc

# wget $tmp_http_ngconf -O ./nginx.conf
# nginx -c $(pwd)/nginx.conf
# wget $tmp_http_ngconf -O /etc/nginx/nginx.conf
cp ./nginx.conf /etc/nginx/nginx.conf
systemctl enable nginx --now

echo "done. Redirected https://*/teams  =>  http://localhost:10000"
echo "v2ray > please turn on insecure for using this dummy cert"

