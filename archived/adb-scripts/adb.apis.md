
```bash
adb shell input tap 300 700
adb shell input tap $x $y
adb shell input swipe $x1 $y1 $x2 $y2
adb shell input swipe $x1 $y1 $x2 $y2 $timeInMilliSecond
adb shell input text 'Hello%sWorld'
adb shell input keyevent 66 #enter
adb shell input keyevent $keyCode
# https://stackoverflow.com/questions/7789826/adb-shell-input-events

adb exec-out screencap -p > screen.png
```

