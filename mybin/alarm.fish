#!/bin/fish

# set alarm_time 1673371835
set alarm_time $argv[1]
echo "CURR TIME: "(date +%s)
echo "alarm time is " $alarm_time ", which is " (math '('$alarm_time-(date +%s)')/60/60' ) "hours in the future"
echo Please set MAX volume and MIN light

# you can also set +20%, +30%, ...
pactl set-sink-volume 0 110%
# pactl set-sink-volume 0 150%

set prefix (dirname (status --current-filename))

while true
    if test (date +%s) -gt $alarm_time # 9:30AM
        while true
            env XDG_RUNTIME_DIR=/run/user/(id -u) mpg123 $prefix/alarm.mp3
            sleep 1
        end
    end
    sleep 5
end

