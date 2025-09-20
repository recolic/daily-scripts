function mailr
    # Send email to root@recolic.net.
    set -l message $argv[1]
    set -l title "[mailr] RECOLIC SHELL NOTIFY"

    echo ">>> Sending email:" root@recolic.net "$title: $message" 1>&2
    curl 'https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title='(echo $title | base64)'&b64Content='(echo "[mailr] $message" | base64 -w 0) 1>&2
    return $status
end

# function decode_vmess_if_any
#     while read line
#         if string match 'vmess://*' "$line" > /dev/null
#             echo $line | sed 's|vmess://||' | base64 -d 2>/dev/null | tr -d '\n'
#             echo
#         else
#             echo $line
#         end
#     end
# end

function getbalance
    # curl -s 'secret' | base64 -d | head -n2 | tail -n1 | sed 's/^.*%BC%9A//' | cut -d % -f 1
    # curl -s 'secret' | base64 -d | decode_vmess_if_any | grep '.u4f59.u989d.uff1a' | sed 's/^.*uff1a//g' | grep -o '^[0-9.]*'
    test "$suburl" = "" ; and echo "ERROR: suburl not set"
    curl -s "$suburl" --user-agent 'Clash/' | grep '余额：[0-9.]*' -o | grep '[0-9.]*' -o | head -n1
end

# run it daily
set bal (getbalance)
echo "DEBUG: bal=$bal"
set bal_valid (python -c "print(1 if $bal>0 and $bal<100 else 0)")
if test "$bal_valid" != 1
    mailr "balancemon.fish broken, balance '$bal'"
    exit 1
end
set alert (python -c "print(1 if $bal<2 else 0)")
if test $alert = 1
    mailr "teffy cloud need recharge, balance $bal"
end
