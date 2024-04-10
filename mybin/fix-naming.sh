#!/bin/bash

function fuck_sym () {
while true; do
    rename "$1" _ * || break
done
}

# remove all leading '-'
for fl in -*; do
    rename -- - _ "$fl" # only once
done

# remove all these special chars
fuck_sym ' '
fuck_sym '('
fuck_sym ')'
fuck_sym '['
fuck_sym ']'
fuck_sym '"'
fuck_sym "'"




