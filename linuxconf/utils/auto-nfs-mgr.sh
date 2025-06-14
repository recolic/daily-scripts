#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

HMS_GOOD=0
HMS_BAD=1
# Function to check if hms.r is reachable
check_reachability_i() {
    if ping -c 1 hms.r &> /dev/null; then
        return $HMS_GOOD # Host is reachable
    else
        return $HMS_BAD # Host is unreachable
    fi
}
check_reachability() {
    for i in {1..20}; do
        check_reachability_i && return $? ; sleep 0.2
    done
    return $HMS_BAD
}
check_mounted() {
    # Warning: df -T might hang forever if NFS is offline!
    df_res=$(df -T) || return $HMS_GOOD # nfs io error. Return mounted=1
    echo "$df_res" | grep nfs && return $HMS_GOOD || return $HMS_BAD
}

#prev_stat=$HMS_GOOD
while true; do
    check_reachability
    net_stat=$?
    if [ $net_stat = $HMS_BAD ]; then
        # Bug fix: if network unavailable, check_mounted might hang.
        umount -f -l /home/recolic/nfs
    else
        check_mounted
        nfs_stat=$?
        if [ $nfs_stat = $HMS_BAD ]; then
            mount -o bg,intr,soft,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
        fi
    fi

    #if [ $net_stat != $nfs_stat ]; then
    #    # Two more double-confirmation. If difference fixed, do not update prev_stat and continue.
    #    sleep 1 ; check_reachability ; [ $? = $nfs_stat ] && continue
    #    sleep 1 ; check_reachability ; [ $? = $nfs_stat ] && continue
    #    echo "$(date) State mismatch detected, network $net_stat but nfs $nfs_stat"

    #    if [ $net_stat = $HMS_BAD ]; then
    #        umount -f -l /home/recolic/nfs
    #    else
    #    fi
    #fi
#    if [ $stat != $prev_stat ]; then
#        # Two more double-confirmation. If difference fixed, do not update prev_stat and continue.
#        sleep 1 ; check_reachability ; [ $? = $prev_stat ] && continue
#        sleep 1 ; check_reachability ; [ $? = $prev_stat ] && continue
#        echo "$(date) State change from $prev_stat to $stat"
#
#        # If still doesn't match prev_stat, do something.
#        if [ $stat = $HMS_BAD ]; then
#            umount -f -l /home/recolic/nfs
#        else
#            mount -o bg,intr,soft,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
#        fi
#    fi
#    prev_stat=$stat
    sleep 2  # Sleep for 3 seconds
done

