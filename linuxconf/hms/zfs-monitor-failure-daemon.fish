#!/usr/bin/fish

echo "Sleep 60s to prevent this daemon being launched too early..."
sleep 60s

while true
    date
    if zpool status | grep 'zpool clear'
        set output (zpool status)
        echo "Detected zpool fail: $output"

        set email_content (echo "Detected zpool fail: $output" | base64 -w 0)
        set email_title (echo "[hms.recolic] ALERT: Zpool failure" | base64 -w 0)
        curl "https://recolic.cc/api/email-notify.php?recvaddr=root@recolic.net&b64Title=$email_title&b64Content=$email_content" 1>&2
    end
    if not zpool status | grep 'errors: No known data errors'
        set output (zpool status)
        echo "Detected zpool fail: $output"

        set email_content (echo "Detected zpool fail: $output" | base64 -w 0)
        set email_title (echo "[hms.recolic] ALERT: Zpool failure" | base64 -w 0)
        curl "https://recolic.cc/api/email-notify.php?recvaddr=root@recolic.net&b64Title=$email_title&b64Content=$email_content" 1>&2
    end
    sleep 1h
end

        
        


