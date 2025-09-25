#!/bin/bash
#Minimal rsec for php
d(){ echo "RSEC error:" "$@" 1>&2; exit 1; }
k=${1#R_SEC_}
da=${RSEC_ENC_DB_ALT:-/etc/RSEC_alt}

if [ -f "$da" ]; then
  cd="$(cat "$da")" || d "load db failure"
else
  d "ENC_DB missing"
fi

if [[ -z "$k" ]]; then
  echo "$cd" | cut -d: -f1 | tr -d ' ' | grep -v '^#' | grep .
else
  rl="$(echo "$cd" | grep -i "^$k *:")" || d "key not found"
  echo "$rl" | sed 's/^[^:]*://' | head -n1
fi
exit $?
