# docker build -t recolic/php-nginx -f Dockerfile .
# Usage: docker run -tid -p 3091:80 -v /srv/html:/var/www/html --name rwww --restart=always recolic/php-nginx /entry.sh
FROM ubuntu:20.04

RUN apt update
RUN DEBIAN_FRONTEND="noninteractive" apt install -y vim git nginx php
# proxy.php requires these modules to work. 
RUN DEBIAN_FRONTEND="noninteractive" apt install -y php-cli php-curl php-fpm php-gd php-json php-mbstring php-xml php-zip
# recolic.net/p wants this
RUN DEBIAN_FRONTEND="noninteractive" apt install -y gpg

RUN rm /etc/nginx/nginx.conf && ln -s /var/www/html/.config/nginx.conf /etc/nginx/nginx.conf
RUN sed -i 's|text/plain[^;]*;|text/plain   txt c cc log cu cpp cxx py java sh bash fish go rs v sv vh h hpp hxx patch list md ps1 conf ini;|g' /etc/nginx/mime.types

COPY entry.sh /
VOLUME /var/www/html



