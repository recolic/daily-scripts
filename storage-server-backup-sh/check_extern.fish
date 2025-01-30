#!/bin/fish
# check if necessary service for external users are running, and start them if not.
# note: tested 4.2GB (4404019200) file upload, webdav server works.

if ps aux | grep [w]ebdav
    exit 0 # service already running
end

set EXTERN_WEBDAV_KEY _PLACEHOLDER_WEBDAV_KEY_

if not test -f /usr/bin/webdav
    set HTTP_PREFIX "https://recolic.net/hms.php?/softwares/bin/linux-amd64"
    wget -O "/usr/bin/webdav" "$HTTP_PREFIX/webdav-server"
    and chmod +x /usr/bin/webdav
    or exit 1
end

if not test -f /etc/webdav.yaml
    echo "
directory: /storage/backups/extern
users:
  - username: extern
    password: $EXTERN_WEBDAV_KEY
    permissions: CRUD
" | tee /etc/webdav.yaml
    or exit 1
end

mkdir -p /storage/backups/extern/
nohup /usr/bin/webdav --config /etc/webdav.yaml > /var/log/extern-server.log 2>&1 & disown

