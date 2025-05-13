#!/bin/bash
# show gpg receipt

fname="$1"
[[ "$fname" = "" ]] && echo "Usage: $0 <file>" && exit 1
echo -n "$fname "
gpg --pinentry-mode cancel --list-packets "$fname" 2>&1 | grep keyid | sed 's/^.*keyid //g'
exit $?


