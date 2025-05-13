#!/usr/bin/fish

cd /storage/storage-server-backup-sh
    or exit $status

source targets.fish

pack_backup_dir $argv
exit $status

