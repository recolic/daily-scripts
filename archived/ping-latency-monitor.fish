#!/usr/bin/env fish

#set target_ip 'www.aliyun.com'
set target_ip '184.174.55.71'
set interval '10m'
# **s for seconds, **m = minutes, **h = hours, **d = days

set temp_file (mktemp)

function string_is_empty
    test (string length "$argv") -eq 0
    return $status
end

function get_latency
    # Get ping average time
    ping $target_ip -c 4 > $temp_file
    set packet_is_loss (grep '100% packet loss' $temp_file)
    if not string_is_empty "$packet_is_loss"
        set ping_time 'LOSS'
    else
        set ping_time (grep 'avg' $temp_file | sed 's/^[^\\/]*\/[^\\/]*\\/[^\\/]*\\/[^\\/]*\\///' | sed 's/\\/.*$//g')
    end
    if string_is_empty "$ping_time"
        echo 'Error: failed ping: ping_time is empty.' > /dev/fd/2
    end
    set curr_time (date -Iseconds)
    echo "$ping_time|$curr_time"
end

echo "ping_time(ms)|curr_time(UTC+8)"

while true
    get_latency
    sleep $interval
end
