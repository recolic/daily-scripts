#!/bin/bash

function check_if_recolicphone_in_lan_once () {
    # return 1 if NOT present. 
    # return 0 if IS present. 
    phone_hostname="RMST-P3X-Pixel-3-XL"
    liveinfo=`curl -s http://10.100.100.1/Info.live.htm` || echo "Failed to download live info"
    mac_niddle=`echo "$liveinfo" | sed 's/}{/\n/g' | grep dhcp_leases | tr -d "'" | grep -o "$phone_hostname,[^,]*,[^,]*" | grep -o ':[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]$'` || return 1
    echo "$liveinfo" | sed 's/}{/\n/g' | grep active_wireless | grep -F "$mac_niddle'," > /dev/null && return 0 || return 1
}

function check_if_recolicphone_in_lan () {
    # We check it 20 times in 20 minutes. If non of them shows "present", it means "recolic has actually left". 
    for i in {0..20}; do
        check_if_recolicphone_in_lan_once && return 0
        sleep 60
    done
    return 1
}

motion_pid=0
while true; do
    sleep 60
    if check_if_recolicphone_in_lan; then
        # recolic is present
        [[ $motion_pid = 0 ]] && continue # already not running
        echo "[`date`] Recolic is back. Stop recording... "
        kill -s SIGINT $motion_pid
        sleep 10 # waiting for motion to exit
        kill $motion_pid
        motion_pid=0
    else
        # recolic is not in house
        [[ $motion_pid != 0 ]] && continue # already running
        echo "[`date`] Recolic left. Start recording... "
        motion &
        motion_pid=$!
    fi
done

echo "[`date`] daemon exiting"

