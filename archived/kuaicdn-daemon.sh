#!/bin/bash

echo "Sleeping 15s before starting script"
sleep 15

chmod o+w /etc/systemd/system /var/run
sleep 1
sudo -u kuaicdn bash -c 'cd /kuaicdn/app && ipes/bin/ipes start' &
sleep 5
# bash -c 'while true; do rm -f /etc/systemd/system/ipesdaemon.service; sleep 5; done' > /dev/null &
chmod o-w /etc/systemd/system /var/run

while true; do
sleep 10000 || break
done

