function mailr
    # Send email to root@recolic.net.
    set -l message $argv[1]
    set -l title "[mailr] RECOLIC SHELL NOTIFY"

    echo ">>> Sending email:" root@recolic.net "$title: $message" 1>&2
    curl 'https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title='(echo $title | base64)'&b64Content='(echo "[mailr] $message" | base64 -w 0) 1>&2
    return $status
end

set curr (curl -s https://api.github.com/repos/TerraFirmaCraft/TerraFirmaCraft/commits/1.18.x | json2table sha -p)

while true
    set res (curl -s https://api.github.com/repos/TerraFirmaCraft/TerraFirmaCraft/commits/1.18.x | json2table sha -p)
    or continue
    if string match -- "*null*" "$res"
        continue
    end

    echo "DEBUG: $res"
    if test "$res" != "$curr" ; and test "$curr" != ""
        mailr "TFC repo updated: new commit is $res , old commit $curr"
    end

    set curr "$res"
    sleep 10m
end


