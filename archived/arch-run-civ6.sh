#!/bin/sh
LD_PRELOAD=.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/x86_64-linux-gnu/libfreetype.so.6.8.0 steam steam://rungameid/289070
# LD_PRELOAD=/usr/lib/libfreetype.so  steam steam://rungameid/289070
exit $?
