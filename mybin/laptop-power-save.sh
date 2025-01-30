#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Laptop: Disable AMD turbo boost to extend battery hours.
echo 0 > /sys/devices/system/cpu/cpufreq/boost
cpupower frequency-set --max 2300000

