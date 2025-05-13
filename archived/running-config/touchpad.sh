#!/bin/bash
# disable / enable touchpad automatically.
# Recolic Keghart, at Jun 25 2017

function assert () {
    $1
    RET_VAL=$?
    if [ $RET_VAL != 0 ]; then
        echo "Assertion failed: $1 returns $RET_VAL."
        if [ "$2" != "" ]; then
            echo "Message: $2"
        fi
        exit $RET_VAL
    fi
}

DEV_ID=`xinput list | grep 'Touchpad' | awk '$1=$1' | cut -d ' ' -f 6 | tr -d 'id='`

echo "Recognized DEV_ID is $DEV_ID."

xinput list-props $DEV_ID | grep 'Device Enabled (141):' | grep '1$'
DEV_DISABLED=$?
if [ "$1" == "on" ]; then
	echo 'Enable touchpad.'
	DEV_DISABLED=1
elif [ "$1" == "off" ]; then
	echo 'Disable touchpad.'
	DEV_DISABLED=0
else
	echo 'Switch touchpad status.'
fi

echo "Setting prop 'Device Enabled' to $DEV_DISABLED"
xinput set-prop $DEV_ID "Device Enabled" $DEV_DISABLED
exit $?
