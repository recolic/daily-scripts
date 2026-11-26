Here is the exact step-by-step upgrade procedure from your running old `rmail`:

### 1. Export data from the old `rmail` container
Dump `vmail` (domains, users, password hashes, aliases, forwardings) with `--complete-insert --no-create-info` so column names are explicit and new `1.8.11` columns get their defaults:
```bash
## Use /root/.my.cnf inside the container (iRedMail saves the MySQL root credentials there):
docker exec rmail mysqldump --defaults-file=/root/.my.cnf --complete-insert --no-create-info --skip-triggers vmail > /tmp/vmail-data.sql
```
*(Optional)* Also back up your DKIM key from the old container so your existing DNS DKIM TXT record stays valid:
```bash
docker cp rmail:/var/lib/dkim /tmp/old-dkim
```

### 2. Stop old `rmail` and back up `/srv/iredmail`
```bash
docker stop rmail
mv /srv/iredmail/mysql /srv/iredmail/mysql.bak-10.3
mkdir -p /srv/iredmail/mysql
```
*(Keep `/srv/iredmail/vmail` as-is — that's where all your actual emails live.)*

### 3. Populate fresh `/srv/iredmail/mysql` from the new image
```bash
docker create --name tmp-init recolic/mail.recolic.net
docker cp -a tmp-init:/var/lib/mysql/. /srv/iredmail/mysql/
docker rm tmp-init
```

### 4. Start the new container (`rmail2`)
Use the new `docker run` command from the top of docker-mail.recolic.net/Dockerfile (with `--name rmail2` until verified):
```bash
docker run -tid -m 1536m --privileged --cgroupns=host \
  -p 3092:443 -p 110:110 -p 995:995 -p 143:143 -p 993:993 -p 25:25 -p 465:465 -p 587:587 \
  -v /srv/iredmail/vmail:/var/vmail \
  -v /srv/iredmail/mysql:/var/lib/mysql \
  -v /srv/iredmail/clamav:/var/lib/clamav \
  -v /srv/conf/acme-sh/mail.recolic.net/mail.recolic.net.key:/etc/ssl/private/iRedMail.key:ro \
  -v /srv/conf/acme-sh/mail.recolic.net/fullchain.cer:/etc/ssl/certs/iRedMail.crt:ro \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --name rmail2 --hostname func.mail.recolic.net recolic/mail.recolic.net /sbin/init
```

Fix ownership inside the container if UIDs differ between Ubuntu 20.04 and 24.04, then restart:
```bash
docker exec rmail2 chown -R mysql:mysql /var/lib/mysql
docker exec rmail2 chown -R vmail:vmail /var/vmail
docker restart rmail2
```

Verify MariaDB and other services are up:
```bash
docker exec rmail2 systemctl --failed --no-pager
```

### 5. Import your old `vmail` data & DKIM keys
Use `--force` (or `sed 's/^INSERT INTO/INSERT IGNORE INTO/'`) so `postmaster@recolic.net` and `recolic.net` created during build don't abort the import on duplicate primary keys:
```bash
sed 's/^INSERT INTO /INSERT IGNORE INTO /' /tmp/vmail-data.sql | docker exec -i rmail2 mysql -u root -p vmail
```
*(Note: if you want your old `postmaster@recolic.net` row/password to overwrite the newly built one, use `REPLACE INTO` instead of `INSERT IGNORE INTO`, or delete the newly created `postmaster@recolic.net` first.)*

If you backed up `/tmp/old-dkim` in step 1:
```bash
docker cp /tmp/old-dkim/. rmail2:/var/lib/dkim/
docker exec rmail2 chown -R amavis:amavis /var/lib/dkim
docker exec rmail2 systemctl restart amavis
```

### 6. Verify & Cutover
Test logging into Roundcube (`https://...:3092/mail/`), iRedAdmin (`https://...:3092/iredadmin/`), and sending/receiving a test email. Once confirmed:
```bash
docker rm rmail
docker rename rmail2 rmail
docker update --restart=always rmail
```
