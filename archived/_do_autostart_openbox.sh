#!/bin/fish
for si in (ls /home/recolic/sh/running-config/autostart-openbox/*.sh)
    eval "$si"
end
