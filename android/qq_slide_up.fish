#!/usr/bin/fish

while true
    #adb shell input touchscreen swipe 530 1620 530 300

    # sshpass -p admin ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 root@10.100.100.172 input touchscreen swipe 530 300 530 1620 170
    adb shell input touchscreen swipe 530 500 530 1620 120
end
