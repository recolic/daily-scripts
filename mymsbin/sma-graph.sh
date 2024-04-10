#!/bin/bash

[[ $f = "" ]] && f="$1"
[[ $f = "" ]] && cat "$0" | grep -E 'then|##' && exit 1

MSDEBUG=~/ms-scripts/msdebug

if [ $f = tv1 ]; then
    ## v1 show session time
    cat sm* | grep aliveTime.ms:[0-9]\* -o | cut -d : -f 2 | python  $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = tv2 ]; then
    ## v2 show session time
    cat sm* | grep aliveTime2=[0-9]\* -o | cut -d = -f 2 | python  $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = tsv2 ]; then
    ## v2 session time -- timestamp
    cat sm* | grep aliveTime2=[0-9]\* | sed 's/T.*=/:/g' | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map-xy.py
elif [ $f = tsv2.so ]; then
    ## v2 session time -- timestamp (success req only!)
    cat sm* | grep aliveTime2=[0-9]\* | grep SUCCEED | sed 's/T.*=/:/g' | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map-xy.py
elif [ $f = msot ]; then
    ## epollpp mapsize (active ctx count) over timestamp
    grep mapsize='[0-9]*' sm* | sed 's/T.*=/:/g' | cut -d ' ' -f 1 | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map-xy.py
elif [ $f = port ]; then
    ## show port number in vfpreq graph
    grep Got.VFP.req sm* | cut -d , -f 1 | sed 's/^.* //g' | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = bin ]; then
    ## show success/fail graph
    grep packetType sm* | sed 's/.*SUCCEEDED.*/1/g' | sed 's/.*FAILED.*/0/g' | grep -v packetType | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = bin-ts ]; then
    ## show success/fail graph by timestamp
    grep --no-filename packetType sm* | grep -E 'SUCCEEDED|FAILED' | sed 's/T.*SUCCEEDED.*$/:1/g' | sed 's/T.*FAILED.*$/:0/g' | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map-xy.py
elif [ $f = ts ]; then
    ## pktCount -- timestamp graph
    grep Got.VFP.req sm* | cut -d T -f 1 | sed 's/^.*://g' | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = cpu ]; then
    ## timestamp count accumulated
    echo aW1wb3J0IGZpbGVpbnB1dAoKZm9yIGwgaW4gZmlsZWlucHV0LmlucHV0KCk6CiAgICBwcmludCgiOiIuam9pbihsLnN0cmlwKCkuc3BsaXQoIjoiKVs6Oi0xXSkpCgo= | base64 -d > /tmp/1.py
    cat sm* | cut -d T -f 1 | uniq -c | sed 's/^ *//g' | tr ' ' : | python /tmp/1.py | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map-xy.py
elif [ $f = cpu2 ]; then
    ## timestamp graph
    cat sm* | cut -d T -f 1 | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = cpumon ]; then
    ## cpumon parse
    num="$2"
    python $MSDEBUG/cpumon/cpumon-parser.py | grep "cpu$num:" | cut -d : -f 2 | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
elif [ $f = cpumon.u ]; then
    ## cpumon parse (calc with USER time)
    num="$2"
    UTIL_CALC=USER python $MSDEBUG/cpumon/cpumon-parser.py | grep "cpu$num:" | cut -d : -f 2 | python $MSDEBUG/draw-sma-fd-mapping/lines-to-map.py
fi

