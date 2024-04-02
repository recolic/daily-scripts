#!/bin/bash

# recolic: this problem is solved on 2020.1.4 archlinux rolling.
# disable this script
exit 0

function x_wayland () {
    echo 'Setting up xrandr for wayland...'
    xrandr --newmode "800x600_60.00"   38.25  800 832 912 1024  600 603 607 624 -hsync +vsync
    xrandr --addmode XWAYLAND0 800x600_60.00
    xrandr --addmode XWAYLAND0 1920x1080
    
    xrandr --newmode "640x480_60.00"   23.75  640 664 720 800  480 483 487 500 -hsync +vsync
    xrandr --addmode XWAYLAND0 640x480_60.00 
}

function x_x () {
    echo 'Setting up xrandr for xorg...'
    xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
    
    xrandr --newmode "800x600_60.00"   38.25  800 832 912 1024  600 603 607 624 -hsync +vsync
    xrandr --addmode eDP1 800x600_60.00
    xrandr --addmode eDP1 1920x1080_60.00
    xrandr --addmode eDP-1-1 800x600_60.00
    xrandr --addmode eDP-1-1 1920x1080_60.00

    xrandr -s 1920x1080
}

xrandr | grep 'XWAYLAND0'
[ $? -eq 0 ] && x_wayland || x_x

exit $?

