#!/bin/bash
#disable or enable system power management.

if grep '#HandleLidSwitch=' /etc/systemd/logind.conf > /dev/null; then
	perl -pi -e 's/#HandleLidSwitch=/HandleLidSwitch=/g' /etc/systemd/logind.conf;
	echo 'Disabled power management.';
else
	perl -pi -e 's/HandleLidSwitch=/#HandleLidSwitch=/g' /etc/systemd/logind.conf;
	echo 'Enabled power management.';
fi
systemctl restart systemd-logind;
