#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

HMS_GOOD=0
HMS_BAD=1
# Function to check if hms.r is reachable
check_reachability() {
    if ping -c 1 hms.r &> /dev/null; then
        return $HMS_GOOD # Host is reachable
    else
        return $HMS_BAD # Host is unreachable
    fi
}

prev_stat=$HMS_GOOD
while true; do
    check_reachability
    stat=$?
    if [ $stat != $prev_stat ]; then
        # Two more double-confirmation. If difference fixed, do not update prev_stat and continue.
        sleep 1 ; check_reachability ; [ $? = $prev_stat ] && continue
        sleep 1 ; check_reachability ; [ $? = $prev_stat ] && continue
        echo "$(date) State change from $prev_stat to $stat"

        # If still doesn't match prev_stat, do something.
        if [ $stat = $HMS_BAD ]; then
            umount -f -l /home/recolic/nfs
        else
            mount -o bg,intr,soft,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
        fi
    fi
    prev_stat=$stat
    sleep 3  # Sleep for 3 seconds
done

