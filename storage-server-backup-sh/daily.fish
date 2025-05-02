#!/usr/bin/fish
# This script must be invoked on every 02:00(UTC+8), which should be 18:00(UTC).
# 0 18 * * * /storage/storage-server-backup-sh/daily.fish >> /var/log/recolic-backup.log 2>&1
#
# This script requires fish 3.x
# Manual run: env DEBUG_TARGET_OVERRIDE=target_mail_www_recolic_net_data ./daily.fish
cd /storage/storage-server-backup-sh
    or exit $status

source targets.fish

function reach_target
    set -l target_name $argv[1]
    echo_log "On day $today, reach target $target_name"

    $target_name
    set -l ret $status

    test $ret = 0 ; or email_notify "Backup system target $target_name failed. I have to give up and notify you. Please resolve this problem manually!"
end

if set -q DEBUG_TARGET_OVERRIDE
    echo "Debug: explicitly run target $DEBUG_TARGET_OVERRIDE"
    reach_target $DEBUG_TARGET_OVERRIDE
else
    # Monthly schedule for jobs
    set today (date -u +%d)
    switch $today
        case 21
            reach_target target_nas_data
        case 24
            reach_target target_nas_home
        case 08 18 27
            reach_target target_mail_www_recolic_net_data
        case 09 19 28
            reach_target target_git_drive_recolic_net_data
        case '*'
            echo "Nothing to do today ($today)."
    end

    # Check if extern target needs packing
    if test -f /storage/cache/target_extern_lwl/NEED_PACKING
        rm -f /storage/cache/target_extern_lwl/NEED_PACKING
        reach_target target_extern_lwl
    end
end

#### Other daily tasks ####

./old-backup-clean.exe /storage/backups

# Send warning if running out of harddisk (less than 100GiB left)
# Modify & test this when moving to new system.
set space_check_df_keyword /dev/mapper/ubuntu--vg-lv--root
test (df -T | grep $space_check_df_keyword | tr -s ' ' | cut -d ' ' -f 3,5 | sed 's/^.* //g') -lt 104857600
    and email_notify "Backup system has low disk space. "(df -Th | grep $space_check_df_keyword)

# Not used by any extern user right now... But still worth keep it running.
fish check_extern.fish

