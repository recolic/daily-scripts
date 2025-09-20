#!/bin/bash

[[ "$1" = "" ]] && echo "$0 fuck-once.sh 12" && exit 1
target="$1"
[[ "$2" = "" ]] && nthreads=8 || nthreads="$2"

echo "
while true; do
    sleep 1
    bash $target
done
" > /tmp/onethread-daemon.sh
for i in $(seq $nthreads); do
    echo LAUNCH: nohup bash onethread-daemon.sh TO log-thread$i.log
    nohup bash /tmp/onethread-daemon.sh >> /tmp/log-thread$i.log 2>&1 & disown
done



