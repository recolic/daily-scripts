#!/bin/bash

logf="$1"
odir="$2"
[[ $logf = "" ]] && echo "Usage: $0 ldc1.txt [out_dir/]" && exit 1
[[ $odir = "" ]] && odir="$logf.decoded"

# env: 1f=1 ; dedup=1

function decode_to_dir () {
  cter=0
  b64_prev=""
  while IFS="" read -r p || [ -n "$p" ]
  do
    ts_t=`echo "$p" | cut -d : -f 1 | tr -d ' '`
    b64=`echo "$p" | cut -d : -f 2`
    cter=$((cter+1))
    [[ "$dedup" = 1 ]] && [[ "$b64_prev" = "$b64" ]] && continue || b64_prev="$b64" # skip
    echo "$b64" | base64 -d | gzip -d > "$odir/$ts_t-$cter.log"
  done <"$logf"
}

function decode_1f () {
  while IFS="" read -r p || [ -n "$p" ]
  do
    ts_t=`echo "$p" | cut -d : -f 1 | tr -d ' '`
    b64=`echo "$p" | cut -d : -f 2`
    [[ "$dedup" = 1 ]] && [[ "$b64_prev" = "$b64" ]] && continue || b64_prev="$b64" # skip
    date -d "@$ts_t" >> "$odir/$logf-one.log"
    echo "$b64" | base64 -d | gzip -d >> "$odir/$logf-one.log"
  done <"$logf"
}

rm -rf "$odir" ; mkdir "$odir" || ! echo "Unable to mkdir $odir" || exit 1
if [[ $1f = 1 ]]; then
    echo "output 1f mode"
    decode_1f
else
    decode_to_dir
fi

