#!/usr/bin/fish

function do_type
    #adb shell input text qiangzhizhuxiaozhanghao
    adb shell input text $argv[1]
    adb shell input keyevent 62
    adb shell input keyevent 66
end


while true
    echo -n '_'
    do_type nimayichangle
    sleep 5
    echo -n '.'
    do_type niquanjiadouyichangle
    sleep 5
end

