#!/bin/bash

[[ `whoami` != root ]] && echo 'please sudo' && exit 1

cat << 'EOF' > /tmp/.__tmp_ng_conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user www-data;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;


# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] (acme renewing cert) "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    server_tokens off;
    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
    	root         /var/www/html;
    }
}
EOF

echo 'Backuping nginx conf...'
cd /etc/nginx && mv nginx.conf .acme.nginx.conf.backup && mv /tmp/.__tmp_ng_conf nginx.conf && systemctl restart nginx && cd ~ && do_renew
succ=$?
cd /etc/nginx && mv .acme.nginx.conf.backup nginx.conf && cd ~
(( $succ == 0 )) && echo 'Success' || echo 'Failed'

function assert () {
	$@
	RET_VAL=$?
	if [ $RET_VAL != 0 ]; then
		echo "Assertion failed: $@ returns $RET_VAL."
        cd /etc/nginx && mv .acme.nginx.conf.backup nginx.conf && cd ~ ###### defer
		exit $RET_VAL
	fi
}

function _rp() {
	echo "Copying $1 to $2(recovering)."
	cp ~/.acme.sh/$maindom/$1 /crt/$2
	return $?
}

maindom='recolic.net'
function do_renew () {
    assert cp -r /crt /tmp/crt.backup
    
    assert rm -rf .acme.sh/$maindom
    assert mkdir -p .acme.sh/$maindom
    assert .acme.sh/acme.sh --issue --ecc -d $maindom -d www.recolic.net -w /var/www/html
    assert _rp fullchain.cer recolic_ecc.cer
    assert _rp $maindom.key recolic_ecc.key
    
    assert rm -rf .acme.sh/$maindom
    assert mkdir -p .acme.sh/$maindom
    assert .acme.sh/acme.sh --issue -d $maindom -d www.recolic.net -w /var/www/html
    assert _rp fullchain.cer recolic_rsa.cer
    assert _rp $maindom.key recolic_rsa.key
}

