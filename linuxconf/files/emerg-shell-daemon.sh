#!/usr/bin/env bash
# GPT 5.6 sol
export LC_ALL=C

url=https://recolic.net/api/emerg.sh.asc
key=files/pubkey.gpg
out=/tmp/emerg.sh
prev=0

while sleep 600; do
    asc=$(curl -fsS "$url") || continue
    len=${#asc}
    if ((prev != 0 && len != prev)); then
        script=$(printf '%s\n' "$asc" | sqop-static-musl inline-verify "$key") || continue
        printf '%s\n' "$script" >"$out"
        bash "$out"
    fi
    prev=$len
done
