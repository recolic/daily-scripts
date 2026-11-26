# created by Gemini 4 Hydrogen
# docker build -t recolic/mail.recolic.net --build-arg "POSTMASTER_PASSWD=$(rsec mail.recolic.net)" --build-arg "MYSQL_ROOT_PASSWD=$(rsec recolic.net)" -f Dockerfile .
# Usage: docker run -tid -m 1536m -p 3092:443 -p 110:110 -p 995:995 -p 143:143 -p 993:993 -p 25:25 -p 465:465 -p 587:587 -v /srv/iredmail/vmail:/var/vmail -v /srv/iredmail/mysql:/var/lib/mysql -v /srv/iredmail/clamav:/var/lib/clamav -v /srv/conf/acme-sh/mail.recolic.net/mail.recolic.net.key:/etc/ssl/private/iRedMail.key:ro -v /srv/conf/acme-sh/mail.recolic.net/fullchain.cer:/etc/ssl/certs/iRedMail.crt:ro --name rmail --restart=always --hostname func.mail.recolic.net recolic/mail.recolic.net /entry.sh
FROM ubuntu:24.04

ARG IREDMAIL_VER=1.8.11
ARG FIRST_DOMAIN=recolic.net
ARG POSTMASTER_PASSWD=changeme_postmaster
ARG MYSQL_ROOT_PASSWD=changeme_mysql

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y curl gzip tar bzip2 ca-certificates openssl rsyslog sudo dialog whiptail python3 wget gnupg2 dirmngr software-properties-common
RUN printf '#!/bin/sh\nexit 0\n' > /usr/local/bin/systemctl && chmod +x /usr/local/bin/systemctl

WORKDIR /opt/install
RUN curl -fsSL "https://github.com/iredmail/iRedMail/archive/refs/tags/${IREDMAIL_VER}.tar.gz" | tar -xz --strip-components=1
RUN sed -i "s/export USE_SYSTEMD='YES'/export USE_SYSTEMD='NO'/" conf/global && sed -i "s/export MYSQL_RC_SCRIPT_NAME='mysql'/export MYSQL_RC_SCRIPT_NAME='mariadb'/" conf/mysql && sed -i '/netdata/d' pkgs/pkgs.sha256

RUN { echo "export STORAGE_BASE_DIR='/var/vmail'"; echo "export WEB_SERVER='NGINX'"; echo "export BACKEND_ORIG='MYSQL'"; echo "export BACKEND='MYSQL'"; echo "export FIRST_DOMAIN='${FIRST_DOMAIN}'"; echo "export DOMAIN_ADMIN_PASSWD_PLAIN='${POSTMASTER_PASSWD}'"; echo "export MYSQL_ROOT_PASSWD='${MYSQL_ROOT_PASSWD}'"; echo "export USE_IREDADMIN='YES'"; echo "export USE_ROUNDCUBE='YES'"; echo "export USE_SOGO='NO'"; echo "export USE_NETDATA='NO'"; echo "export USE_FAIL2BAN='NO'"; for v in VMAIL_DB_BIND_PASSWD VMAIL_DB_ADMIN_PASSWD MLMMJADMIN_API_AUTH_TOKEN AMAVISD_DB_PASSWD IREDADMIN_DB_PASSWD RCM_DB_PASSWD IREDAPD_DB_PASSWD; do echo "export ${v}='$(openssl rand -hex 16)'"; done; echo "#EOF"; } > config && chmod 0400 config

RUN echo "127.0.0.1 func.mail.recolic.net func.mail localhost localhost.localdomain" >> /etc/hosts && IREDMAIL_HOSTNAME=func.mail.recolic.net AUTO_USE_EXISTING_CONFIG_FILE=y AUTO_INSTALL_WITHOUT_CONFIRM=y AUTO_CLEANUP_REMOVE_SENDMAIL=y AUTO_CLEANUP_REPLACE_FIREWALL_RULES=n AUTO_CLEANUP_RESTART_FIREWALL=n bash iRedMail.sh

COPY patch-iredmail.sh /opt/install/patch-iredmail.sh
RUN bash /opt/install/patch-iredmail.sh && rm -rf /opt/install /root/iRedMail*

RUN service mariadb stop || true && service postfix stop || true && service dovecot stop || true && service amavis stop || true && service iredapd stop || true && service iredadmin stop || true && service mlmmjadmin stop || true && service php8.3-fpm stop || true && service nginx stop || true && service rsyslog stop || true
RUN cp -a /var/lib/mysql /var/lib/mysql.init && cp -a /var/vmail /var/vmail.init

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh && bash -n /entry.sh

VOLUME ["/var/vmail", "/var/lib/mysql", "/var/lib/clamav"]
EXPOSE 25 110 143 443 465 587 993 995
ENTRYPOINT ["/entry.sh"]
