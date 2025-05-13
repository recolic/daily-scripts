#!/bin/bash

[ "$1" == "" ] && echo 'Usage: ./this.sh mod.jar mod2.jar ...' && exit 1
curr=`pwd`

function _get () {
    tmpd="/tmp/.$1.dir"
    [ -e $tmpd ] && rm -rf $tmpd
    mkdir $tmpd
    cp $1 $tmpd/ && cd $tmpd > /dev/null || return 2
    unzip $1 > /dev/null || return 2
    
    echo "$1->"
    cat mcmod.info || return 2
}

for fn in "$@"
do
    _get $fn || echo 'failed to resolve '"$fn"
    cd $curr > /dev/null
done

