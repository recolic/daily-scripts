#!/bin/bash

function assert () {
    CMD="$*"
    $CMD
    RET_VAL=$?
    if [ $RET_VAL != 0 ]; then
        echo "Assertion failed: $CMD returns $RET_VAL."
        exit $RET_VAL
    fi
}

src='git@github.com:xxxxx/xxxxx.git'
dst='git@github.com:xxxxx/xxxxx.git'

rm -rf sk
assert git clone $dst
assert mv xxxxx sk
assert mv sk/.git gitdat-dst
assert rm -rf sk
assert git clone $src
assert mv xxxxx sk
assert mv sk/.git gitdat-src
