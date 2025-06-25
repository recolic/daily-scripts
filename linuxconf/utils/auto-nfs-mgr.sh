#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

GOOD=0
BAD=1
# Function to check if hms.r is reachable
check_reachability_i() {
    if ping -c 1 hms.r &> /dev/null; then
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
    echo "$df_res" | grep nfs && return $GOOD || return $BAD
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
        umount -f -l /home/recolic/nfs # Bug: umount could also block!!!
        log "after umount"
    else
        check_mounted
        nfs_stat=$?
        log "check mounted=$nfs_stat"
        if [ $nfs_stat = $BAD ]; then
            log "before mount"
            mount -o bg,intr,hard,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
            log "after mount"
        fi
    fi
    sleep 2  # Sleep for 3 seconds
done

