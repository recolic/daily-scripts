
function enter_multiselect
    adb shell input touchscreen swipe 432 1309 432 1309 1000
    adb shell input touchscreen tap 867 1131
    adb shell input touchscreen swipe 432 1109 432 1109 1000
    adb shell input touchscreen tap 867 931
end

function multiselect_delete
    adb shell input touchscreen tap 144 2650
    sleep 0.5
    adb shell input touchscreen tap 710 2414
end

function peek_msgs_3
    adb shell input touchscreen tap 750 700
    adb shell input touchscreen tap 750 1264
    adb shell input touchscreen tap 750 1863
#    adb shell input touchscreen tap 750 2280
end

function swipe_down
    adb shell input touchscreen swipe 530 1620 530 200 500
    sleep 1
end

while true
    enter_multiselect

    peek_msgs_3
    swipe_down
    peek_msgs_3
    swipe_down
    peek_msgs_3
    swipe_down
    peek_msgs_3
    swipe_down
    peek_msgs_3
    swipe_down
    peek_msgs_3
    swipe_down
    peek_msgs_3
    swipe_down

    multiselect_delete
    sleep 1
end
    


