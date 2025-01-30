#!/bin/bash

[[ "$1" = "" ]] && nthreads=8 || nthreads="$1"
for i in $(seq $nthreads); do
    echo LAUNCH: nohup bash onethread-daemon.sh TO log-thread$i.log
    nohup bash onethread-daemon.sh >> log-thread$i.log 2>&1 & disown
done

    


