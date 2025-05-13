


cat "$1" | grep '^[0-f][0-f]' | sed 's/^[^ ]*  //g' | sed 's/  .*$//g' | tr - ' ' > /tmp/tmp.txt
xxd -r -p /tmp/tmp.txt output.bin

