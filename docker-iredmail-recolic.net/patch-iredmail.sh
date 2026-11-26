#!/bin/bash
# created by Gemini 4 Hydrogen
set -euo pipefail

# 1. Disable heavy clamav & spamassassin, keep DKIM via amavisd
sed -i 's/^@bypass_virus_checks_maps.*/@bypass_virus_checks_maps = (1);/; s/^@bypass_spam_checks_maps.*/@bypass_spam_checks_maps  = (1);/' /etc/amavis/conf.d/50-user
python3 -c "p='/etc/amavis/conf.d/50-user'; s=open(p).read(); import re; m=re.search(r'^@storage_sql_dsn\s*=\s*(\([^\n]+\));', s, re.M); s=(s.replace(m.group(0), '@lookup_sql_dsn = ' + m.group(1) + ';\n# ' + m.group(0)) if m else s); s=s.replace('@lookup_sql_dsn = @storage_sql_dsn;', '# @lookup_sql_dsn = @storage_sql_dsn;'); open(p,'w').write(s)"
apt-get purge -y clamav clamav-daemon clamav-freshclam clamav-base || true
apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# 2. Disable greylisting & enable reject_sender_login_mismatch in iRedAPD
python3 -c "p='/opt/iredapd/settings.py'; s=open(p).read(); import re; s=re.sub(r'[\"\x27]greylisting[\"\x27],?\s*', '', s); s=s if 'reject_sender_login_mismatch' in s else s.replace('plugins = [', 'plugins = [\"reject_sender_login_mismatch\", '); open(p,'w').write(s)"

# 3. Fix facebook HELO rule
if [ -f /etc/postfix/helo_access.pcre ]; then python3 -c "p='/etc/postfix/helo_access.pcre'; s=open(p).read(); line='/^\\\\d{1,3}-\\\\d{1,3}-\\\\d{1,3}-\\\\d{1,3}\\\\.mail-mail\\\\.facebook\\\\.com$/ DUNNO\n'; open(p,'w').write(s if line in s else line+s)"; fi

# 4. Allow larger attachment size (100MB)
postconf -e message_size_limit=104857600
postconf -e mailbox_size_limit=104857600
PHP_INI=$(ls /etc/php/*/fpm/php.ini | head -n1)
sed -i 's/^memory_limit =.*/memory_limit = 200M/; s/^upload_max_filesize =.*/upload_max_filesize = 100M/; s/^post_max_size =.*/post_max_size = 100M/' "$PHP_INI"
if [ -f /etc/nginx/conf-enabled/client_max_body_size.conf ]; then sed -i 's/client_max_body_size .*/client_max_body_size 100m;/' /etc/nginx/conf-enabled/client_max_body_size.conf; fi
RCM_CFG=/opt/www/roundcubemail/config/config.inc.php
if [ -f "$RCM_CFG" ]; then grep -q "max_message_size" "$RCM_CFG" && sed -i "s/.*max_message_size.*/\$config['max_message_size'] = '100M';/" "$RCM_CFG" || echo "\$config['max_message_size'] = '100M';" >> "$RCM_CFG"; fi

# 5. Set Roundcube session timeout to 99999 min
if [ -f "$RCM_CFG" ]; then grep -q "session_lifetime" "$RCM_CFG" && sed -i "s/.*session_lifetime.*/\$config['session_lifetime'] = 99999;/" "$RCM_CFG" || echo "\$config['session_lifetime'] = 99999;" >> "$RCM_CFG"; fi

# 6. Remove amavis/clamav filename extension ban
python3 -c "import re; p='/etc/amavis/conf.d/50-user'; s=open(p).read(); s=re.sub(r'\\\$banned_filename_re\s*=\s*new_RE\([^;]*\);', '\$banned_filename_re = undef;', s, flags=re.S); open(p,'w').write(s)"
echo '$banned_filename_re = undef;' >> /etc/amavis/conf.d/50-user

# 7. Enable IPv6 in postfix & dovecot
postconf -e inet_protocols=all
sed -i 's/^listen =.*/listen = * [::]/' /etc/dovecot/dovecot.conf

# 8. Fix firstrade proxyvote problem (comment out reject_unknown_helo_hostname)
sed -i 's/^\([[:space:]]*\)reject_unknown_helo_hostname/\1# reject_unknown_helo_hostname/' /etc/postfix/main.cf

# 9. Ensure SSL cert paths match external volume mount (/etc/ssl/private/iRedMail.key & /etc/ssl/certs/iRedMail.crt)
if [ -f /etc/nginx/templates/ssl.tmpl ]; then sed -i 's|ssl_certificate .*|ssl_certificate /etc/ssl/certs/iRedMail.crt;|; s|ssl_certificate_key .*|ssl_certificate_key /etc/ssl/private/iRedMail.key;|' /etc/nginx/templates/ssl.tmpl; fi
postconf -e smtpd_tls_cert_file=/etc/ssl/certs/iRedMail.crt
postconf -e smtpd_tls_key_file=/etc/ssl/private/iRedMail.key
sed -i 's|^ssl_cert =.*|ssl_cert = </etc/ssl/certs/iRedMail.crt|; s|^ssl_key =.*|ssl_key = </etc/ssl/private/iRedMail.key|' /etc/dovecot/dovecot.conf
