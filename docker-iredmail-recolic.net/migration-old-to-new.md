# created by Gemini 4 Hydrogen

**run all commands with fish**

## 1. Export from old server

```fish
docker exec rmail mysqldump --defaults-file=/root/.my.cnf --complete-insert --no-create-info --skip-triggers vmail > /tmp/vmail-data.sql
```

## 2. Stop old; initialize new storage

```fish
docker stop rmail
mv /srv/iredmail/mysql /srv/iredmail/mysql.bak-10.3
mkdir -p /srv/iredmail/mysql
docker create --name tmp-init recolic/mail.recolic.net
docker cp -a tmp-init:/var/lib/mysql/. /srv/iredmail/mysql/
docker rm tmp-init
```

## 3. Start new container

```fish
docker run -tid -m 1536m --privileged --cgroupns=host -p 3092:443 -p 110:110 -p 995:995 -p 143:143 -p 993:993 -p 25:25 -p 465:465 -p 587:587 -v /srv/iredmail/vmail:/var/vmail -v /srv/iredmail/mysql:/var/lib/mysql -v /srv/iredmail/clamav:/var/lib/clamav -v /srv/conf/acme-sh/mail.recolic.net/mail.recolic.net.key:/etc/ssl/private/iRedMail.key:ro -v /srv/conf/acme-sh/mail.recolic.net/fullchain.cer:/etc/ssl/certs/iRedMail.crt:ro -v /sys/fs/cgroup:/sys/fs/cgroup:rw --name rmail2 --hostname func.mail.recolic.net recolic/mail.recolic.net /sbin/init

docker exec rmail2 chown -R mysql:mysql /var/lib/mysql
docker exec rmail2 chown -R vmail:vmail /var/vmail
docker restart rmail2
docker exec rmail2 systemctl --failed --no-pager
```

## 4. Import through staging database

**run all commands with fish**

Do not import the old dump directly: the schemas differ.

```fish
docker exec rmail2 systemctl stop nginx php8.3-fpm iredadmin mlmmjadmin dovecot postfix amavis iredapd
docker exec rmail2 mysql --defaults-file=/root/.my.cnf -e "DROP DATABASE IF EXISTS vmail_migrate; CREATE DATABASE vmail_migrate"
for table in (docker exec rmail2 mysql --defaults-file=/root/.my.cnf -N -B -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='vmail' AND TABLE_TYPE='BASE TABLE'")
    docker exec rmail2 mysql --defaults-file=/root/.my.cnf -e "CREATE TABLE vmail_migrate.`$table` LIKE vmail.`$table`"
end
docker exec rmail2 mysql --defaults-file=/root/.my.cnf -e "ALTER TABLE vmail_migrate.mailbox ADD COLUMN lastlogindate datetime NULL, ADD COLUMN lastloginipv4 int UNSIGNED NULL, ADD COLUMN lastloginprotocol varchar(255) NULL, ADD COLUMN allowedsenders text NULL, ADD COLUMN rejectedsenders text NULL, ADD COLUMN allowedrecipients text NULL, ADD COLUMN rejectedrecipients text NULL"
cat /tmp/vmail-data.sql | docker exec -i rmail2 mysql --defaults-file=/root/.my.cnf vmail_migrate
```

Must return `0`:

```fish
docker exec rmail2 mysql --defaults-file=/root/.my.cnf -e "SELECT COUNT(*) FROM vmail_migrate.mailbox WHERE NULLIF(allowedsenders,'') IS NOT NULL OR NULLIF(rejectedsenders,'') IS NOT NULL OR NULLIF(allowedrecipients,'') IS NOT NULL OR NULLIF(rejectedrecipients,'') IS NOT NULL"
```

```fish
for table in domain domain_admins mailbox forwardings last_login deleted_mailboxes used_quota
    set columns (docker exec rmail2 mysql --defaults-file=/root/.my.cnf -N -B -e "SELECT GROUP_CONCAT(CONCAT('`',COLUMN_NAME,'`') ORDER BY ORDINAL_POSITION) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='vmail' AND TABLE_NAME='$table'")
    docker exec rmail2 mysql --defaults-file=/root/.my.cnf -e "SET FOREIGN_KEY_CHECKS=0; TRUNCATE TABLE vmail.`$table`; INSERT INTO vmail.`$table` ($columns) SELECT $columns FROM vmail_migrate.`$table`; SET FOREIGN_KEY_CHECKS=1"
end

docker exec rmail2 mysql --defaults-file=/root/.my.cnf -N -B -e "SELECT 'domain',(SELECT COUNT(*) FROM vmail.domain),(SELECT COUNT(*) FROM vmail_migrate.domain) UNION ALL SELECT 'domain_admins',(SELECT COUNT(*) FROM vmail.domain_admins),(SELECT COUNT(*) FROM vmail_migrate.domain_admins) UNION ALL SELECT 'mailbox',(SELECT COUNT(*) FROM vmail.mailbox),(SELECT COUNT(*) FROM vmail_migrate.mailbox) UNION ALL SELECT 'forwardings',(SELECT COUNT(*) FROM vmail.forwardings),(SELECT COUNT(*) FROM vmail_migrate.forwardings) UNION ALL SELECT 'last_login',(SELECT COUNT(*) FROM vmail.last_login),(SELECT COUNT(*) FROM vmail_migrate.last_login) UNION ALL SELECT 'deleted_mailboxes',(SELECT COUNT(*) FROM vmail.deleted_mailboxes),(SELECT COUNT(*) FROM vmail_migrate.deleted_mailboxes) UNION ALL SELECT 'used_quota',(SELECT COUNT(*) FROM vmail.used_quota),(SELECT COUNT(*) FROM vmail_migrate.used_quota)"
```

Only if every pair of counts matches:

```fish
docker exec rmail2 mysql --defaults-file=/root/.my.cnf -e "DROP DATABASE vmail_migrate"
docker exec rmail2 systemctl start iredapd amavis postfix dovecot iredadmin mlmmjadmin php8.3-fpm nginx
```

## 5. Update DKIM DNS

Get the new public DKIM record from the container:

```fish
docker exec rmail2 amavisd showkeys
```

test with

```
docker exec rmail2 amavisd testkeys
```

## (optional) 6. Verify and cut over

```fish
docker exec rmail2 systemctl --failed --no-pager
curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:3092/mail/
docker rename rmail2 rmail
docker update --restart=always rmail
```
