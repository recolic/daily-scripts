#!/bin/fish
for si in (ls /home/recolic/sh/running-config/autostart/*.sh)
    eval "$si & disown"
end
