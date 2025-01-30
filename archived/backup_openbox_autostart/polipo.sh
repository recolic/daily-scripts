#!/bin/bash

exit 0 # Replaced by proxychains
systemd-cat -t autostart-polipo polipo -c /home/recolic/.poliporc &
