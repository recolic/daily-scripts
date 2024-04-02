#!/bin/bash

sudo wpa_supplicant -i wlp4s0 -c/etc/wpa_supplicant.conf -B > /tmp/.out
systemd-cat -t autostart-wpa_sup cat /tmp/.out

