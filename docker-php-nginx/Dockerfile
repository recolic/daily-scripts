# docker build -t recolic/php-nginx -f Dockerfile .
# Usage: docker run -tid -p 3091:80 -v /srv/html:/var/www/html --name rwww --restart=always recolic/php-nginx /entry.sh
FROM ubuntu:24.04

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim git nginx php8.3
# proxy.php requires these modules to work. php-curl is widely used.
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y php8.3-cli php8.3-curl php8.3-fpm php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip
# recolic.net/p wants this
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y gpg
# GPT bash script wants this
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y curl ca-certificates

RUN dpkg --compare-versions "$(dpkg-query -W -f='${Version}' php8.3-common)" ge 8.3.6-0ubuntu0.24.04.13
RUN dpkg --compare-versions "$(dpkg-query -W -f='${Version}' php8.3-cli)" ge 8.3.6-0ubuntu0.24.04.13
RUN dpkg --compare-versions "$(dpkg-query -W -f='${Version}' php8.3-fpm)" ge 8.3.6-0ubuntu0.24.04.13

RUN rm /etc/nginx/nginx.conf && ln -s /var/www/html/.config/nginx.conf /etc/nginx/nginx.conf
RUN sed -i 's|text/plain[^;]*;|text/plain   txt c cc log cu cpp cxx py java sh bash fish go rs v sv vh h hpp hxx patch list md ps1 conf ini;|g' /etc/nginx/mime.types

RUN test -d /etc/php/8.3
RUN printf '%s\n' 'upload_max_filesize = 16M' 'post_max_size = 16M' 'cgi.fix_pathinfo = 0' 'session.upload_progress.enabled = Off' 'expose_php = Off' 'log_errors = On' > /etc/php/8.3/fpm/conf.d/99-security.ini
RUN printf '%s\n' 'php_admin_flag[session.upload_progress.enabled] = off' 'php_admin_value[cgi.fix_pathinfo] = 0' >> /etc/php/8.3/fpm/pool.d/www.conf

COPY entry.sh /
RUN bash -n /entry.sh
RUN mkdir -p /run/php
RUN php-fpm8.3 -t
VOLUME /var/www/html



