#!/bin/sh

#portrait (left)

if [[ $1 = left ]]; then
xrandr -o left
xinput set-prop 10 --type=float 'Coordinate Transformation Matrix' 0 -1 1 1 0 0 0 0 1
#xinput set-prop  --type=float 'Coordinate Transformation Matrix' 0 -1 1 1 0 0 0 0 1
fi


#landscape (normal)
if [[ $1 = normal ]]; then
xrandr -o normal
xinput set-prop 10 --type=float 'Coordinate Transformation Matrix' 0 0 0 0 0 0 0 0 0
#xinput set-prop 'Your Touchpad&#039;s name, if applicable' --type=float 'Coordinate Transformation Matrix' 0 0 0 0 0 0 0 0 0
fi
