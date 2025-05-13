#!/bin/bash

function init-daemons () {
    [[ ! -f /var/www/html/.config/nginx.conf ]] && echo "This docker image requires volume /var/www/html and existance of /var/www/html/.config/nginx.conf" && return 1

    echo '----- Launching daemons -----'
    nginx || return $? # auto fork
    mkdir -p /run/php
    php-fpm7.4 || return $? # auto fork
    # cron # auto fork, for acme.sh # Removed because https managed outside docker
    echo '----- Done! -----'
}

init-daemons &&
/bin/bash

exit $?

