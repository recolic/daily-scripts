#!/bin/bash


[[ $(id -u) = 0 ]] && ping_fld="-f"

function confirm_alive () {
    local host="$1"
    timeout 4s ping "$host" -c 1
    local ret="$?"
    [[ $ret != 124 ]] && [[ $ret != 2 ]] && return $ret
    for i in {1..4}; do
        timeout 12s ping "$host" -c 1 $ping_fld && return 0
        sleep 1
    done
    return 124
}

function restart_ssr () {
    [[ $ssr_pid != '' ]] && kill -9 $ssr_pid
    confirm_alive www.aliyun.com > /dev/null 2>&1 || return 124
    sslocal -c /home/recolic/sh/proxy/iplc/iplc.ss.json &
    ssr_pid=$!
    sleep 1
    ps -p $ssr_pid ; return $?
}

failing=0
restart_ssr

while true; do
    if proxychains -q curl -s https://google.com/ > /dev/null; then
        failing=0
    else
        echo 'LOG: Failed to access https://google.com/'
        if [[ $failing = 1 ]]; then
            while true; do
                echo 'LOG: Restart ssr...'
                restart_ssr && break
                echo 'LOG: Failed to restart ssr. Return '$?
                sleep 20
            done
            failing=0
        else
            failing=1
        fi
    fi
    sleep 60
done


