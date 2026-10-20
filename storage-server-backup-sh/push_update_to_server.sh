#!/bin/sh

set -e

rsync . root@storage.recolic.cc:/storage/storage-server-backup-sh -avz --progress --delete

davkey=$(rsec AZ_BLOB_SAS) &&
    ssh root@storage.recolic.cc sed -i "s|_PLACEHOLDER_BLOBSAS_URL_|$davkey|" /storage/storage-server-backup-sh/targets.fish ||
    echo "ERROR!! Failed to update secret"

