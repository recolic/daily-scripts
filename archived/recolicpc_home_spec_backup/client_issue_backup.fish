#!/usr/bin/fish

########## DO NOT EDIT: copied. 
function echo_log # args... -> int
    echo -n "[" (date --utc) "]" >> /dev/fd/2
    echo $argv >> /dev/fd/2
    return $status
end

function email_notify # string -> int
    # Send email to root@recolic.net.
    set -l message $argv[1]

    echo_log ">>> Sending email:" root@recolic.net "RECOLIC STORAGE SYSTEM NOTIFY" "[storage.recolic.net] $message"
    curl "https://recolic.net/api/email-notify.php?apiKey=$R_SEC_MAILAPI_KEY&recvaddr=root@recolic.net&b64Title="(echo "RECOLIC STORAGE SYSTEM NOTIFY" | base64)'&b64Content='(echo "[storage.recolic.net] $message" | base64) 1>&2
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

########### DO NOT EDIT END.

set remote_host 'root@storage.recolic.cc'

# About 25GB, 10 hours.
function target_recolicpc_home
    run_until_success rsync -avz --partial --delete \
        --exclude /nfs/ --exclude /extraDisk/ --exclude /superExtraDisk/ --exclude /Downloads/ --exclude /tmp/ --include /.config/fish/ --exclude "/.*/" \
        /home/recolic/ $remote_host:/storage/backups/target_recolicpc_home

    and echo "Waiting for remote: creating archive..."
    and ssh $remote_host /storage/storage-server-backup-sh/_remote_pack_backup_dir.fish /storage/backups/target_recolicpc_home
    return $status
end

if test "$R_SEC_MAILAPI_KEY" = ""
    echo ERROR need secret
    exit 1
end

target_recolicpc_home

