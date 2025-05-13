#!/bin/bash

existing_fl="$1"

[[ $existing_fl = '' ]] && echo "Usage: $0 <existing sha256 file> files..." && exit 1

shift

function get_sha256_from_fl () {
    fname="$1"
    grep "  $fname$$" "$existing_fl"
}

for fl in "$@"
do
    sha=`get_sha256_from_fl "$fl"`
    if [[ "$sha" = '' ]]; then
        sha256sum "$fl"
    else
        echo "$sha"
    fi
done



