#!/usr/bin/env bash
# Run this every 1min as root
# GPT 5.4


#!/usr/bin/env bash
set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "must run as root" >&2; exit 1; }

TAG="#__script_managed"

check_wlo_available() {
  nmcli d | grep -qw MSFTGUEST && ping -c1 -W1 mspc.wlo.m.recolic >/dev/null 2>&1
}

etc_hosts_get() {
  awk -v host="$1" '$2 == host { print $1; exit }' /etc/hosts
}

etc_hosts_set() {
  local host="$1" ip="$2" current_ip

  current_ip="$(etc_hosts_get "$host" || true)"
  [ "$current_ip" = "$ip" ] && return 0

  sed -i -E "s|^[0-9.]+[[:space:]]+${host//./\\.}[[:space:]]+$TAG\$|$ip $host $TAG|" /etc/hosts
}

  if check_wlo_available; then
    etc_hosts_set mspc.m.recolic "$(etc_hosts_get mspc.wlo.m.recolic)"
  else
    etc_hosts_set mspc.m.recolic "$(etc_hosts_get mspc.corp.m.recolic)"
  fi

