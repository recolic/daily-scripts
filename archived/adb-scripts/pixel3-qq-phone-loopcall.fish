
function fuck_wenjuan
    adb shell input touchscreen tap 738 1321
    sleep 1
    adb shell input touchscreen tap 85 2691
end

set i 1
while true
    adb shell input touchscreen tap 1000 2350
    adb shell input touchscreen tap 1000 2200
    adb shell input touchscreen tap 1000 2100
    sleep 10
    set i (math $i+1)
    if test (math $i%16) = 0
        fuck_wenjuan
    end
end



