#!/bin/bash

xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync


xrandr --newmode "800x600_60.00"   38.25  800 832 912 1024  600 603 607 624 -hsync +vsync
xrandr --addmode eDP1 800x600_60.00
xrandr --addmode eDP1 1920x1080_60.00

