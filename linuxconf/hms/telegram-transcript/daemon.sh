#!/bin/bash

function email_notify () {
    # Send email to root@recolic.net.
    message="$1"
    echo ">>> Sending email:" root@recolic.net "RECOLIC HMS NOTIFY" "[HMS] $message"
    curl 'https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title='$(echo "RECOLIC HMS NOTIFY" | base64 -w0)'&b64Content='$(echo "[recolic hms] $message" | base64 -w0) 1>&2
    return $?
}

mkdir -p /mnt/fsdisk/tmp/tg-transcript-workdir
script_dir="$(pwd)"
cd /mnt/fsdisk/tmp/tg-transcript-workdir &&
cp $script_dir/tools_simpledb_dump.py.html ./ || email_notify "telegram-transcript daemon failed"

export mode=http
nohup python $script_dir/$(dirname $0)/tools_simpledb_dump.py $audit_port $audit_token & disown

python $script_dir/$(dirname $0)/tg-transcript.py || email_notify "telegram-transcript daemon failed"
