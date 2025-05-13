#!/usr/bin/fish

# Secret. Will be replaced by push_update_to_server.sh
set MAILAPI_KEY _PLACEHOLDER_MAILKEY_

function echo_log # args... -> int
    echo -n "[" (date --utc) "]" >> /dev/fd/2
    echo $argv >> /dev/fd/2
    return $status
end

function email_notify # string -> int
    # Send email to root@recolic.net.
    set -l message $argv[1]

    echo_log ">>> Sending email:" root@recolic.net "RECOLIC STORAGE SYSTEM NOTIFY" "[storage.recolic.net] $message"
    curl "https://recolic.net/api/email-notify.php?apiKey=$MAILAPI_KEY&recvaddr=root@recolic.net&b64Title="(echo "RECOLIC STORAGE SYSTEM NOTIFY" | base64 -w0)'&b64Content='(echo "[storage.recolic.net] $message" | base64 -w0) 1>&2
    return $status
end

function run_until_success # args... -> int
    set _rimpl_fail_count 0
    while test $_rimpl_fail_count -lt 32
        $argv
        and return 0
        # On failure
        set _rimpl_fail_count (math 1+$_rimpl_fail_count)
    end
    # Fails for more than 32 times.
    echo_log "Command '$argv' has been failing for 32 times. Give up."
    return 1
end

function pack_backup_dir # string -> int
    set -l dirname $argv[1]

    set -l datestr (date -u +%Y%m%d-%H%M%S)
    set -l fname "/storage/backups/"(basename $dirname)"_packed.tar.gz.v"$datestr
    mkdir -p /storage/backups

    if test -e $fname
        echo_log Warning: filename conflict at "'"$fname"'". Overwriting...
    end

    echo_log "Compressing backup folder..."
    tar -czf $fname $dirname
    and echo_log "$fname done. Calculating checksum..."
    and sha256sum $fname >> "/storage/backups/SHA256SUM"
    return $status
end

########################### Targets begin #############################

function target_nas_data
    run_until_success rsync -avz --partial --delete --no-links \
        root@remote.nfs.recolic:/mnt/fsdisk/nfs/backups /storage/cache/target_nas_data

    # replica only, skip history version packing.
    # and pack_backup_dir /storage/cache/target_nas_data
    return $status
end

function target_nas_home
    run_until_success rsync -avz --partial --delete --no-links \
        --exclude /Downloads/ --exclude /nfs/ --exclude /tmp/ \
        root@remote.nfs.recolic:/root/ /storage/cache/target_nas_home

    and pack_backup_dir /storage/cache/target_nas_home
    return $status
end

# This script only backup data(/srv) for my websites.
# Use AWS ECR to backup private images, and use Docker HUB to backup public images.
function target_git_drive_recolic_net_data
    # drive.recolic.net, git.recolic.net.
    run_until_success rsync -avz --partial --delete \
        --exclude /srv/mirrors/mirrors/ \
        root@func.drive.recolic:/srv /storage/cache/target_git_drive_recolic_net_data

    and pack_backup_dir /storage/cache/target_git_drive_recolic_net_data
end

function target_mail_www_recolic_net_data
    # mail.recolic.net, www.recolic.net.
    run_until_success rsync -avz --partial --delete \
        --exclude /srv/html/tmp/ \
        root@func.main.recolic:/srv /storage/cache/target_mail_www_recolic_net_data

    and pack_backup_dir /storage/cache/target_mail_www_recolic_net_data
end

function target_extern_lwl
    pack_backup_dir /storage/cache/target_extern_lwl
end



