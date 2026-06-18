function msgr
    # Send IM msg to root@recolic.net
    set -l message $argv[1]
    
    echo ">>> Sending msg: $message" 1>&2
    curl "https://recolic.net/api/telegram-notify.php?b64Content="(echo "$message" | base64 -w 0) 1>&2
    return $status
end
