# Run on receiver side

CONNECT=/mingw64/bin/connect.exe
TMPF=./transfer.tmp

echo REQ | "$CONNECT" 10.100.100.101 8001 > "$TMPF"
received_size=`stat -c %s "$TMPF"`

if [ $received_size -lt 32 ]; then
    if grep INVAL "$TMPF"; then
        echo "INVALid response"
        rm -f "$TMPF" ; exit 2
    fi
fi

echo "Received $TMPF size $received_size"

