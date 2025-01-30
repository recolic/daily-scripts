#!/bin/fish

# set alarm_time 1673371835
set alarm_time $argv[1]

if test "$alarm_time" = ""
    echo "Usage: ./this.fish 1673371835"
    echo "Usage: ./this.fish '+15 min'"
    echo "Usage: ./this.fish +2hour"
    echo "CURR TIME: "(date +%s)
    exit
end
if string match -- '+*' "$alarm_time"
    set new_time (date +%s -d "$alarm_time")
    or exit 1
    set alarm_time $new_time
end

echo "CURR TIME: "(date +%s)
echo "alarm time is " $alarm_time ", which is " (math '('$alarm_time-(date +%s)')/60/60' ) "hours in the future"


function should_trigger
    if test (date +%s) -gt $alarm_time
        return 0
    end
    if test (cat /sys/class/power_supply/AC/online) != 1
        echo "!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!! NO AC POWER, system could suspend!"
        return 0 # ALARM! no power supply.
    end
    return 1
end

set prefix (dirname (status --current-filename))
if not set -q alarm_fish_vol
    set alarm_fish_vol 110%
end
if not set -q alarm_fish_file
    set alarm_fish_file $prefix/alarm.mp3
end

while true
    if should_trigger
        for sn in (pactl list short sinks | cut -f 1)
            # you can also set relative +20%, +30%, ...
            env XDG_RUNTIME_DIR=/run/user/(id -u) pactl set-sink-volume $sn $alarm_fish_vol
            env XDG_RUNTIME_DIR=/run/user/(id -u) pactl set-sink-mute $sn false
        end
        env XDG_RUNTIME_DIR=/run/user/(id -u) paplay $alarm_fish_file
        # env XDG_RUNTIME_DIR=/run/user/(id -u) mpg123 $alarm_fish_file > /dev/null 2>&1
    end
    if test "$alarm_fish_beep_once" = 1
        break
    end
    sleep 5
end

