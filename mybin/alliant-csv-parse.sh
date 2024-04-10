#!/bin/bash

what=$1
fname="$2"

function _help () {
    echo "Usage: this_script <CN/other> <fname>" && exit 1
}
[[ $1 = "" ]] || [[ $2 = "" ]] && _help

if [[ $what = CN ]]; then
    cat "$fname" | grep '^Date' # title line
    cat "$fname" | grep -E 'CN"|(CN *|ALP.*)CREDIT"'
elif [[ $what = other ]]; then
    cat "$fname" | grep -vE 'CN"|(CN *|ALP.*)CREDIT"' | grep -v PAYMENT-ONLINE
else
    _help
fi

