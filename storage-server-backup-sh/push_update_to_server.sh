#!/bin/sh
rsync . root@storage.recolic.cc:/storage/storage-server-backup-sh -avz --progress --delete

[[ "$R_SEC_MAILAPI_KEY" != "" ]] &&
    ssh root@storage.recolic.cc sed -i "s/_PLACEHOLDER_MAILKEY_/$R_SEC_MAILAPI_KEY/" /storage/storage-server-backup-sh/targets.fish ||
    echo "ERROR!! Failed to update MAIL APIKEY"

