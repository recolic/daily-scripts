#!/bin/fish
echo '
function h
    set nfsdir $HOME/nfs
    if not test -d $nfsdir/.henc
        echo "Error: $nfsdir/.henc not exist"
        return 1
    end
    set mountdir /tmp/hshell.mount # Firefox want fixed data directory
    mkdir -p $mountdir
    echo "++ Mount $nfsdir/.henc to $mountdir..."
    encfs --extpass="genpasswd .henc" $nfsdir/.henc $mountdir
    or return $status

    env RECOLIC_ENV_NAME=HSHELL_NFS fish --private -C "cd $mountdir"

    echo "-- umount $mountdir..."
    sudo umount -l -f $mountdir
    rmdir $mountdir
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

