#!/bin/bash
# created by Gemini 4 Hydrogen
set -e

if ! grep -q "func.mail.recolic.net" /etc/hosts; then echo "127.0.0.1 func.mail.recolic.net func.mail localhost localhost.localdomain" >> /etc/hosts; fi

if [ ! -d /var/lib/mysql/mysql ]; then echo "Initializing /var/lib/mysql from template..."; cp -a /var/lib/mysql.init/. /var/lib/mysql/; fi
chown -R mysql:mysql /var/lib/mysql

if [ ! -d /var/vmail/vmail1 ]; then echo "Initializing /var/vmail from template..."; cp -a /var/vmail.init/. /var/vmail/; fi
chown -R vmail:vmail /var/vmail

echo "----- Launching daemons -----"
if [ -x /usr/sbin/rsyslogd ]; then /usr/sbin/rsyslogd || true; fi
service mariadb start
for i in $(seq 1 30); do mysqladmin ping --silent && break || sleep 1; done
service iredapd start || true
service amavis start || true
service dovecot start
service postfix start
PHP_FPM=$(ls /etc/init.d/php*-fpm | head -n1 | xargs basename)
service "$PHP_FPM" start
if [ -f /opt/www/iredadmin/rc_scripts/uwsgi/debian.ini ]; then mkdir -p /var/run/iredadmin && chown iredadmin:iredadmin /var/run/iredadmin && chmod 0755 /var/run/iredadmin && /usr/bin/uwsgi --ini /opt/www/iredadmin/rc_scripts/uwsgi/debian.ini --pidfile /var/run/iredadmin/iredadmin.pid --daemonize /var/log/iredadmin.log; fi
service nginx start
echo "----- Done! -----"

trap 'service postfix stop; service dovecot stop; service mariadb stop; exit 0' TERM INT
while true; do sleep 60 & wait $!; done
