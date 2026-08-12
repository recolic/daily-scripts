#!/bin/bash

function email_notify () {
    # Send email to root@recolic.net.
    message="$1"
    echo ">>> Sending email:" root@recolic.net "RECOLIC HMS NOTIFY" "[HMS] $message"
    curl 'https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title='$(echo "RECOLIC HMS NOTIFY" | base64 -w0)'&b64Content='$(echo "[recolic hms] $message" | base64 -w0) 1>&2
    return $?
}

script_dir="$(pwd)/$(dirname $0)"

mkdir -p /mnt/fsdisk/tmp/tg-transcript-workdir
cd /mnt/fsdisk/tmp/tg-transcript-workdir

python $script_dir/main.py || email_notify "telegram-transcript daemon failed"
