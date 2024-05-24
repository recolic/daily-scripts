function mailr
    # Send email to root@recolic.net.
    set -l message $argv[1]
    set -l title "[mailr] RECOLIC SHELL NOTIFY"

    echo ">>> Sending email:" root@recolic.net "$title: $message" 1>&2
    curl 'https://recolic.net/api/email-notify.php?apiKey=8f353e3f-3803-4694-bc3d-77993bc9bdef&recvaddr=root@recolic.net&b64Title='(echo $title | base64)'&b64Content='(echo "[mailr] $message" | base64 -w 0) 1>&2
    return $status
end

set curr (curl https://api.github.com/repos/TerraFirmaCraft/TerraFirmaCraft/commits/1.18.x | json2table sha -p)

while true
    set res (curl https://api.github.com/repos/TerraFirmaCraft/TerraFirmaCraft/commits/1.18.x | json2table sha -p)
    or continue
    echo "DEBUG: $res"
    if test "$res" != "$curr"
        mailr "TFC repo updated: new commit is $res , old commit $curr"
    end

    set curr "$res"
    sleep 10m
end


