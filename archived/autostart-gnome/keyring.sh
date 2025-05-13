#!/bin/bash

while true; do
    ~/code/gnome-keyring-yubikey-unlock/unlock_keyrings.sh ~/keys/rgnome-keyring.passwd && echo 1 > /tmp/.rkeyring-inited
        break
done

exit $?
