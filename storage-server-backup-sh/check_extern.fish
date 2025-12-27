#!/bin/fish

if ps aux | grep [w]ebdav
    exit 0 # service already running
end

set -x EXTERN_WEBDAV_KEY _PLACEHOLDER_WEBDAV_KEY_
# set -x EXTERN_DIR      /storage/backups/extern # Not in use yet
set -x EXTERN_DIR        /storage/tmp

curl https://recolic.net/setup/setup-webdav.sh | bash
