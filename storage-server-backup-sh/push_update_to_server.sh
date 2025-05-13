#!/bin/sh

set -e

rsync . root@storage.recolic.cc:/storage/storage-server-backup-sh -avz --progress --delete

mailkey=$(rsec MAILAPI_KEY) &&
    ssh root@storage.recolic.cc sed -i "s/_PLACEHOLDER_MAILKEY_/$mailkey/" /storage/storage-server-backup-sh/targets.fish ||
    echo "ERROR!! Failed to update MAIL APIKEY"

davkey=$(genpasswd extern@storage) &&
    ssh root@storage.recolic.cc sed -i "s/_PLACEHOLDER_WEBDAV_KEY_/$davkey/" /storage/storage-server-backup-sh/check_extern.fish ||
    echo "ERROR!! Failed to update webdav KEY"

