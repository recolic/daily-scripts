#!/usr/bin/env bash
# call me every 10min
set -euo pipefail

ensure_sleep() {
  systemctl stop nginx
  sleep 5
  hdparm -y /dev/disk/by-id/ata-ST4000NM0035-1V4107_ZC14G486
  hdparm -y /dev/disk/by-id/ata-TOSHIBA_HDWE140_Z9JZK1XJFBRG
}

ensure_active() {
    systemctl is-active --quiet nginx || systemctl start nginx
}

hour=$(TZ=America/Los_Angeles date +%H)

if (( 10#$hour >= 23 || 10#$hour < 3 )); then
  ensure_sleep
else
  ensure_active
fi

