#!/bin/bash

ifile="$1"

cat "$ifile" | while read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" = sleep* ]] && echo "SLEEP: $line" && $line && continue
    [[ "$line" = '#'* ]] && continue
    echo "EXECUTE: $line"
    virtualtype.py "$line
"
done

