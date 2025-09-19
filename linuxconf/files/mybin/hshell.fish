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
    mount | grep -F $mountdir ; and echo "Dangerous: $mountdir already mounted" ; and return 1
    mkdir -p $mountdir ; or return $status
    echo "++ Mount $encfsdir to $mountdir..."
    encfs --extpass="genpasswd $pswd_seed" $encfsdir $mountdir ; or return $status

    env "RECOLIC_ENV_NAME=$envname" fish --private -C "cd $mountdir"

    echo "-- umount $mountdir..."
    sudo umount -l -f $mountdir
    rmdir $mountdir
end

function h
    _secret_mount $HOME/nfs/.henc /tmp/hshell.mount .henc HSHELL_NFS
end

function rb
    mkdir -p /tmp/.rbackup.mount/C2_M
    ln -sf $HOME/nfs/backups/I2 /tmp/.rbackup.mount/
    ln -sf $HOME/nfs/backups/MX /tmp/.rbackup.mount/

    _secret_mount $HOME/nfs/backups/C2_M /tmp/.rbackup.mount/C2_M C2_M HSHELL_RB
end

function x
    _secret_mount $HOME/.config/chromium/Default/GPUShader /tmp/.projx .projx PROJ_X
end

function ff2
    mkdir -p $HOME/tmp/.ffgoogle2
    firefox --no-remote --profile $HOME/tmp/.ffgoogle2
end
function ffl
    mkdir -p $HOME/tmp/h/.ff
    firefox --no-remote --profile $HOME/tmp/h/.ff
end

function henc_local
    echo "encfs -f /mnt/fsdisk/nfs/.henc tmp/m"
    echo "genpasswd .henc | toclip"
    echo "Ctrl-C when done"
end

# set nfsu (mount | grep "$HOME/nfs " >/dev/null; or echo 1); test "$nfsu" = "1"; and rnfs.mount
# test "$nfsu" = "1"; and echo "umount nfs..." ; and sudo umount -f -l $HOME/nfs

if test -d $HOME/tmp/h
    cd $HOME/tmp/h
end
' > /tmp/.hs.fish

gpgconf --reload gpg-agent # Next PIN would be required.
env RECOLIC_ENV_NAME=HSHELL fish --private -C 'source /tmp/.hs.fish'

