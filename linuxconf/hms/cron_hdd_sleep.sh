#!/usr/bin/env bash
# call me every 10min
set -euo pipefail

STATE_FILE="/tmp/.sleeping"

ensure_sleep() {
  if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "1" ]]; then
    return
  fi

  systemctl stop nginx
  sleep 5
  hdparm -y /dev/disk/by-id/ata-ST4000NM0035-1V4107_ZC14G486
  hdparm -y /dev/disk/by-id/ata-TOSHIBA_HDWE140_Z9JZK1XJFBRG

  echo 1 > "$STATE_FILE"
}

ensure_active() {
  if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "0" ]]; then
    return
  fi

  systemctl start nginx
  echo 0 > "$STATE_FILE"
}

hour=$(TZ=America/Los_Angeles date +%H)

if (( hour >= 23 || hour < 3 )); then
  ensure_sleep
else
  ensure_active
fi

