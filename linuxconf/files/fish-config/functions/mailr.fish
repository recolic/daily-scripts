# Defined interactively
function mailr
    # Send email to root@recolic.net, or otheres
    set -l message $argv[1]
    set -l recv "root@recolic.net"
    set -l title "[mailr] RECOLIC SHELL NOTIFY"
    set -l extra ""

    if test -n "$argv[2]"
        set recv $argv[2]
        set extra "&apiKey="(rsec MAILAPI_KEY)
    end

    echo ">>> Sending email:" $recv "$title: $message" 1>&2
    curl "https://recolic.net/api/email-notify.php?recvaddr=$recv&b64Title="(echo $title | base64)'&b64Content='(echo "[mailr] $message" | base64 -w 0)$extra 1>&2
    return $status
end
