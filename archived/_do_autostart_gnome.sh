#!/bin/fish
for si in (ls /home/recolic/sh/running-config/autostart-gnome/*.sh)
    eval "$si & disown"
end
