#!/bin/bash

[ "$IMPL" = "" ] && IMPL=nfs

# Check if script is run as root
if [ "$IMPL" = nfs ]; then
    [[ $(whoami) = root ]] || ! echo "IMPL=nfs: This script must be run as root." || exit 1
elif [ "$IMPL" = sshfs ]; then
    [[ $(whoami) = recolic ]] || ! echo "IMPL=sshfs: This script must be run as recolic." || exit 1
fi
impl_mount () {
    if [ "$IMPL" = nfs ]; then
        mount -o bg,intr,hard,timeo=1,retrans=1,actimeo=1,retry=1 hms.recolic:/ /home/recolic/nfs
    elif [ "$IMPL" = sshfs ]; then
        sshfs hms.recolic:/mnt/fsdisk/nfs /home/recolic/nfs -o reconnect
    fi
}
impl_umount () {
    if [ "$IMPL" = nfs ]; then
        umount -f -l /home/recolic/nfs # Bug: umount could also block!!!
    elif [ "$IMPL" = sshfs ]; then
        fusermount -u -z nfs
    fi
}

GOOD=0
BAD=1
# Function to check if hms.recolic is reachable
check_reachability_i() {
    if ping -c 1 hms.recolic &> /dev/null; then
        return $GOOD # Host is reachable
    else
        return $BAD # Host is unreachable
    fi
}
check_reachability() {
    ip a | grep "inet 10.100.100" || return $BAD
    for i in {1..20}; do
        check_reachability_i && return $GOOD ; sleep 0.1
    done
    return $BAD
}
check_mounted() {
    # Warning: df -T might hang forever if NFS is offline!
    df_res=$(df -T) || return $GOOD # nfs io error. Return mounted=1
    echo "$df_res" | grep /home/recolic/nfs && return $GOOD || return $BAD
}
log() {
    echo "$(date)" "$@" >> /home/recolic/.cache/nfs.log
}

while true; do
    log "wake"
    check_reachability
    net_stat=$?
    log "check_reachability=$net_stat"
    if [ $net_stat = $BAD ]; then
        # Bug fix: if network unavailable, check_mounted might hang.
        log "before umount"
        impl_umount
        log "after umount"
    else
        check_mounted
        nfs_stat=$?
        log "check mounted=$nfs_stat"
        if [ $nfs_stat = $BAD ]; then
            log "before mount"
            impl_mount
            log "after mount"
        fi
    fi
    sleep 2  # Sleep for 3 seconds
done

