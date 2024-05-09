#!/bin/bash

logf="$1"
odir="$2"
[[ $logf = "" ]] && echo "Usage: [f=1] [dedup=1] $0 ldc1.txt [out_dir]" && exit 1
[[ $odir = "" ]] && odir="$logf.decoded"

# env: f=1 ; dedup=1

#b64_prev_2=""
#b64_prev_1=""
function dedup_check () {
    # return 0 for no-skip, 1 for skip
    [[ "$dedup" != 1 ]] && return 0
    [[ "$b64_prev_2" = "$1" ]] || [[ "$b64_prev_1" = "$1" ]] && _skip=1 || _skip=0
    b64_prev_2="$b64_prev_1"
    b64_prev_1="$1"
    return $_skip
}

function decode_to_dir () {
  cter=0
  while IFS="" read -r p || [ -n "$p" ]
  do
    ts_t=`echo "$p" | cut -d : -f 1 | tr -d ' '`
    b64=`echo "$p" | cut -d : -f 2`
    cter=$((cter+1))
    dedup_check "$b64" || continue
    echo "$b64" | base64 -d | gzip -d > "$odir/$ts_t-$cter.log"
  done <"$logf"
}

function decode_1f () {
  while IFS="" read -r p || [ -n "$p" ]
  do
    ts=`echo "$p" | cut -d : -f 1 | tr -d ' ' | grep -o '[0-9]*'`
    b64=`echo "$p" | cut -d : -f 2`
    dedup_check "$b64" || continue
    date --utc -d "@$ts" >> "$odir/$logf-one.log"
    echo "$b64" | base64 -d | gzip -d >> "$odir/$logf-one.log"
  done <"$logf"
}

rm -rf "$odir" ; mkdir "$odir" || ! echo "Unable to mkdir $odir" || exit 1
if [[ $f = 1 ]]; then
    echo "output f mode"
    decode_1f
else
    decode_to_dir
fi

