#!/bin/sh

grub-reboot 'Windows Boot Manager (on /dev/sda1)' &&
reboot

exit $?
