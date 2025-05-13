#!/usr/bin/fish

while true
    adb shell input touchscreen tap 946 404
    sleep 1.2
    adb shell input touchscreen tap 1375 444
    sleep 0.2
    adb shell input touchscreen tap 996 1523
    sleep 0.4
    continue

    

    adb shell input touchscreen tap 1390 370
    sleep 0.2
    adb shell input touchscreen tap 728 1100
    sleep 0.3

    adb shell input touchscreen tap 1390 370
    sleep 0.2
    adb shell input touchscreen tap 728 930
    sleep 0.2

    adb shell input touchscreen tap 996 1523
    sleep 0.2
end
