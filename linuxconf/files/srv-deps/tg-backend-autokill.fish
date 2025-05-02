
function is_tg_window_opened
    if test $XDG_SESSION_TYPE = wayland
        return 0 # doesnt work for wayland
    end
    xprop -root _NET_CLIENT_LIST |
        pcregrep -o1 '# (.*)' |
        sed 's/, /\n/g' |
        xargs -I{} -n1 xprop -id {} _GTK_APPLICATION_ID |
        grep org.telegram.desktop
    return $status
    # returns 0 if telegram window is opened in frontend.
end

function is_tg_running
    ps aux | grep -v grep | grep telegram-desktop
    return $status
    # returns 0 if telegram process is running
end

while true
    sleep 5
    if is_tg_running ; and not is_tg_window_opened
        # Must double confirm before kill. maybe tg is starting...
        sleep 5
        if is_tg_running ; and not is_tg_window_opened
            echo "KILL TELEGRAM!"
            pkill -9 telegram-deskto
        end
    end
end


