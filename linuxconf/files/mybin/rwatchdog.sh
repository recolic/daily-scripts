#!/bin/bash
# recolic's worker watchdog, to send a notify whenever necessary.
#   - set morning wake-up alarm, with conscious detection
#   - receive river cloud alarm by cron
#   - conscious detection in work day, especially while working from another timezone
# with additional functionality, such as
#   - set work mode / pre-work mode (aka morning alarm, turns into work-mode on time) / non-work mode
#   - set leave timer
#   - sleep 30min more
#   - soft beep & hard beep (& crazy beep?)
#   - prevent suspend
# and it should detect
#   - leaving/sleeping without leave timer
#   - being mute
#   - low battery
#   - [OPT] wrong timezone set
#   - [OPT] time out of sync
# TODO: DO NOT suspend system on power button (lid close)
# TODO: DO NOT suspend system on timeout (simulate video site)
# TODO: use fish_promot as additional conscious check


# const variables
MORNING_ALARM="08:38"
[[ $1 = daemon ]] && cloudalarm_token=$(rsec WEAK10)
TMP_CTL_FILE=/tmp/.rwatchdog.cmd
TMP_INFO_FILE=/tmp/.rwatchdog.alarm-info

# stateful variables
mode=work # work / nonwork
leave_timer_until=0 # in local timezone, in sec
alarm_state=ack # 'soft 3/2/1/0' / 'soft' / 'hard' / 'ack'
cloudalarm_prev=""


function play_alarm_once () {
    echo "CALL alarm $alarm_state..."
    case "$alarm_state" in
        "hard")
            alarm_fish_beep_once=1 alarm.fish 0
            ;;
        "soft"*)
            alarm_fish_vol=70% alarm_fish_file=/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga alarm_fish_beep_once=1 alarm.fish 0
            local counter=$(echo "$alarm_state" | cut -d ' ' -f 2)
            if [[ "$counter" =~ ^[0-9]+$ ]]; then
                if [[ "$counter" -le 1 ]]; then
                    alarm_state=hard
                else
                    alarm_state="soft "$(($counter - 1))
                fi
            fi
            ;;
        "office")
            alarm_fish_vol=70% alarm_fish_file=/usr/share/sounds/freedesktop/stereo/bell.oga alarm_fish_beep_once=1 alarm.fish 0
            sleep 10
            ;;
    esac
}

function _alarm () { alarm_state="$1" ; echo "alarm.reason=$2" | tee "$TMP_INFO_FILE" ; }

function pid_check_cron () {
    if [[ $(cat /tmp/.watchdog.pid) != $$ ]]; then
        _err="only one daemon could be running. Curr pid $$ not equal to /tmp/.watchdog.pid"
    fi
}

function river_cloudalarm_cron () {
    echo $FUNCNAME
    local API_URL="https://recolic.net/res/river/alarm-btn/api.php?action=touch&token=$cloudalarm_token"
    
    local curr=$(timeout 20 curl -s "$API_URL" | grep -oP '^alert=\K.*') || ! echo "HTTP GET FAILED. Check token" || return 1

    if [[ "" = "$cloudalarm_prev" ]]; then
        cloudalarm_prev="$curr"
    elif [[ "$curr" = "" ]]; then
        :
    elif [[ "$curr" != "$cloudalarm_prev" ]]; then
        cloudalarm_prev="$curr"
        return 1 # Got Alarm
    fi
    return 0 # Nothing
}

function low_battery_check_cron () {
    echo $FUNCNAME

    if [[ $(cat /sys/class/power_supply/AC/online) = 1 ]] ; then
        return 101 # AC pluged in, no need to check battery percentage at all.
    fi
    if [ -d /sys/class/power_supply ] && [ -z "$(ls -A /sys/class/power_supply)" ]; then
        return 101 # Not laptop.. no need to check
    fi

    bat_percent=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep percentage: | grep '[0-9]*' -o) || _err="Failed to get battery percentage"
    return "$bat_percent"
}
function time_check_cron () {
    echo $FUNCNAME
    
    # TODO: check if time is synced
    if [[ $(date +%z) != -0700 ]] && [[ $(date +%z) != -0800 ]]; then
        _err="invalid tz"
        return 1
    fi

    # auto sign off
    if [[ $(date +%H) = 19 ]]; then
        echo "++ auto signoff"
        mode=nonwork
    fi
    return 0 # good
}

function conscious_check_cron () {
    echo $FUNCNAME
    local idle_time=$(gdbus call --session --dest org.gnome.Mutter.IdleMonitor --object-path /org/gnome/Mutter/IdleMonitor/Core --method org.gnome.Mutter.IdleMonitor.GetIdletime | grep uint64 | cut -d , -f 1 | cut -d ' ' -f 2)
    if [[ "$idle_time" = "" ]]; then
        _err="idle check FAILED. gnome is not available?"
        return 0
    fi
    curr_time=$(date +%s)
    if [[ $leave_timer_until -gt $curr_time ]]; then
        # no alarm if leave timer is active
        echo "++ Leave timer active, conscious_check in" $(( ($leave_timer_until-$curr_time)/60  )) "min.."
        return 0 # OK
    fi
    if [[ "$idle_time" -gt 1200000 ]]; then # 20min in ms
        return 1 # idle too long
    fi
}

function check_ctl_msg () {
    # ctl msg:
    #   set_mode work/nonwork
    #   arm_timer <timestamp>
    #   alarm_ack
    if [[ -f "$TMP_CTL_FILE" ]] && msg=$(cat "$TMP_CTL_FILE") && rm -f "$TMP_CTL_FILE"; then
        while IFS= read -r line; do
            echo "DEBUG: CONTROL MSG: $line"
            local _arg_1=$(echo "$line" | cut -d ' ' -f 1)
            local _arg_2=$(echo "$line" | cut -d ' ' -f 2)
            if [[ $_arg_1 = set_mode ]]; then
                mode="$_arg_2"
            elif [[ $_arg_1 = arm_timer ]]; then
                leave_timer_until="$_arg_2"
            elif [[ $_arg_1 = alarm_ack ]]; then
                alarm_state=ack
            else
                echo "Error: unknown control msg"
            fi
        done <<< "$msg"
    fi
}


op="$1"

if [[ "$op" = "leave" ]]; then
    leave_timer=$(date +%s -d "$2") || ! echo "ERROR invalid leave timer value. Example: $0 $1 '+1 hour'" || exit 1
    echo "arm_timer $leave_timer" >> $TMP_CTL_FILE
    echo "alarm_ack"           >> $TMP_CTL_FILE
elif [[ "$op" = "night" ]]; then
    alarm_ts=$(date +%s -d "today $MORNING_ALARM")
    curr_time=$(date +%s)
    if [[ $curr_time -gt $alarm_ts ]]; then
        alarm_ts=$(date +%s -d "tomorrow $MORNING_ALARM")
    fi
    if [ $(( ($alarm_ts-$curr_time)/60 - 16*60 )) -gt 0 ]; then
        echo "!! Refused to arm timer in more than 16 hours."
        exit 1
    fi
    echo "++ Arm leave timer to morning and switch to 'work' mode, in $( echo "($alarm_ts-$curr_time)/60/60" | bc -l ) hr"
    echo "arm_timer $alarm_ts" >> $TMP_CTL_FILE
    echo "set_mode work"       >> $TMP_CTL_FILE
elif [[ "$op" = "ack" ]]; then
    echo "alarm_ack"           >> $TMP_CTL_FILE
    [[ -f "$TMP_INFO_FILE" ]] && cat "$TMP_INFO_FILE" && rm -f "$TMP_INFO_FILE"
elif [[ "$op" = "work" ]] || [[ "$op" = "nonwork" ]]; then
    echo "set_mode $op"        >> $TMP_CTL_FILE
    echo "alarm_ack"           >> $TMP_CTL_FILE
elif [[ "$op" = "daemon" ]]; then
    :
else
    echo "ERROR: Supported operation: leave +1hour ; night ; ack ; work ; nonwork ; daemon"
fi

if [[ "$op" != "daemon" ]]; then
    ps aux | grep 'rwatchdog.sh [d]aemon' || ! echo -e "\033[1;31m ERROR\nERROR\nERROR: rwatchdog daemon is not running. \033[0m"
    exit $?
fi

######### daemon mode # code BEGINS ########

echo "TEST soft alarm once, to make sure vol is working..."
alarm_state=soft
play_alarm_once
alarm_state=ack

echo $$ > /tmp/.watchdog.pid

while true; do
    check_ctl_msg

    pid_check_cron
    time_check_cron
    river_cloudalarm_cron  ; cloudalarm=$?
    low_battery_check_cron ; bat=$?
    conscious_check_cron   ; too_idle=$?

    ################# All Alarm Policy ###################
    _sticky=1
    if [[ "$mode" = "work" ]]; then
        [[ $bat -lt 30 ]] && _alarm soft "battery lower than 30" && _sticky=0
        [[ $too_idle = 1 ]] && _alarm "soft 7" "you have been idle for too long"
    fi
    [[ $bat -lt 7 ]] && _alarm soft "battery lower than 7" && _sticky=0
    [[ $cloudalarm = 1 ]] && _alarm "soft 3" "river cloudalarm notification"
    [[ "$_err" != "" ]] && _alarm soft "Script Error: $_err"


    while [[ $alarm_state != ack ]]; do
        if nmcli d | grep MSFTGUEST > /dev/null ; then
            echo "Patch: alarm_state=office if connected to MSFTGUEST" 1>&2
            alarm_state=office
        fi
        play_alarm_once
        [ $_sticky = 0 ] && break
        sleep 8
        check_ctl_msg
    done
    sleep 60
done

