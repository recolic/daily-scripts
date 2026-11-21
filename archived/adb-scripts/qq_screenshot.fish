#!/usr/bin/fish

set i 100000
while true
    adb exec-out screencap -p > screen-$i.png
    #google pixel 2 xl#adb shell input touchscreen swipe 530 1620 530 200 500
    # adb shell input touchscreen swipe 530 1620 530 200 500 # pixel 3 xl.qq
    #samsung a9100#adb shell input touchscreen swipe 530 1620 530 600 500
    
    # sshpass -p admin ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 root@10.100.100.172 screencap -p > screen-$i.png
    # sshpass -p admin ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 root@10.100.100.172 input touchscreen swipe 530 1620 530 600 500

    # pixel 3 xl Alipay
    adb shell input touchscreen swipe 530 1620 530 200 400

    set i (math $i+1)
end
