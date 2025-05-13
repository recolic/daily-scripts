#!/bin/bash
# remote=root@hms.recolic
remote="$1"

ssh $remote "arecord -f cd -D plughw:1" | ffplay -nodisp - &
arecord -f cd -D plughw:1 | ssh $remote ffplay -nodisp -

