# Defined interactively
function mailr
    # Send email to root@recolic.net.
    set -l message $argv[1]
    set -l title "[mailr] RECOLIC SHELL NOTIFY"

    echo ">>> Sending email:" root@recolic.net "$title: $message" 1>&2
    curl "https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title="(echo $title | base64)'&b64Content='(echo "[mailr] $message" | base64 -w 0) 1>&2
    return $status
end
