#!/bin/sh

set -e

rsync . root@storage.recolic.cc:/storage/storage-server-backup-sh -avz --progress --delete

echo "---- START upload secret ----"
s=$(rsec AZ_BLOB_SAS)
ssh root@storage.recolic.cc sed -i "'s|_PLACEHOLDER_BLOBSAS_|$s|'" /storage/storage-server-backup-sh/targets.fish
s=$(getent hosts qrtag.recolic | cut -d ' ' -f 1)
ssh root@storage.recolic.cc sed -i "'s|_PLACEHOLDER_QRTAGIP_|$s|'" /storage/storage-server-backup-sh/targets.fish

