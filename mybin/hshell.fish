#!/bin/fish
echo '
function _secret_mount
    set encfsdir $argv[1]
    set mountdir $argv[2]
    set pswd_seed $argv[3]
    set envname $argv[4]

    if not test -d $encfsdir
        echo "Error: $encfsdir not exist"
        return 1
    end
    mkdir -p $mountdir ; or return $status
    echo "++ Mount $encfsdir to $mountdir..."
    encfs --extpass="genpasswd $pswd_seed" $encfsdir $mountdir ; or return $status

    env "RECOLIC_ENV_NAME=$envname" fish --private -C "cd $mountdir"

    echo "-- umount $mountdir..."
    sudo umount -l -f $mountdir
    rmdir $mountdir
end

function h
    # Firefox want fixed data directory (mountdir)
    _secret_mount $HOME/nfs/.henc /tmp/hshell.mount .henc HSHELL_NFS
end

function rbackup
    _secret_mount $HOME/nfs/backups_enc /tmp/.rbackup.mount backups_enc HSHELL_RB
end

function m
    set mountdir (mktemp -d)
    echo "++ Mount DRIVE to $mountdir..."
    sudo mount --uuid f4a5b62c-1a98-4ae4-b121-cd8b06cff603 $mountdir
    or return $status

    env RECOLIC_ENV_NAME=HSHELL_M fish --private -C "cd $mountdir"

    echo "-- umount $mountdir..."
    sudo umount -l -f $mountdir
    rmdir $mountdir
end
' > /tmp/.hs.fish

env RECOLIC_ENV_NAME=HSHELL fish --private -C 'source /tmp/.hs.fish'

