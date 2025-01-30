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

assert cd sk
assert mv ../gitdat-src .git
pullres=`git pull`
nochange=0
if [ "$pullres" == "Already up-to-date." ]; then
	nochange=1
fi
assert mv .git ../gitdat-src
if [ $nochange -eq 1 ]; then
	echo 'Sync ok, no change.'
	exit 0
fi
assert mv ../gitdat-dst .git
assert git add .
assert git commit -m anonymous_sync
assert git push
assert mv .git ../gitdat-dst
assert cd -
