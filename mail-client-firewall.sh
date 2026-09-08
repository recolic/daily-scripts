#!/bin/bash
# created by GPT-6 Astra
# Run as root. Requires iptables, ip6tables, ipset and GNU getent. For Docker bridge/NAT published ports.
# Port 25 stays unrestricted. Failed lookups leave existing rules and allowlists unchanged.
set -euo pipefail
hosts=(www.recolic.cc git.recolic.cc proxy.recolic.cc storage.recolic.cc us1.896444.xyz jp3.896444.xyz sg2.896444.xyz)
ports=(465 587 110 995 143 993)

for cmd in iptables ip6tables ipset getent; do
    command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done

refresh_allowlist() {
    local name="$1" family="$2" ip rest
    ipset create "$name" hash:ip family "$family" -exist
    ipset create "$name-next" hash:ip family "$family" -exist
    ipset flush "$name-next"
    while read -r ip rest; do
        if [[ $family == inet && $ip != *:* || $family == inet6 && $ip == *:* ]]; then ipset add "$name-next" "$ip" -exist; fi
    done <<< "$addresses"
    ipset swap "$name-next" "$name"
    ipset destroy "$name-next"
}

refresh_firewall_rules() {
    local fw="$1" name="$2" port
    local -a rule
    "$fw" -w -S DOCKER-USER >/dev/null 2>&1 || "$fw" -w -N DOCKER-USER
    for port in "${ports[@]}"; do
        rule=(-p tcp -m conntrack --ctdir ORIGINAL --ctstate DNAT --ctorigdstport "$port" -m set ! --match-set "$name" src -j DROP)
        "$fw" -w -C DOCKER-USER "${rule[@]}" 2>/dev/null || "$fw" -w -I DOCKER-USER 1 "${rule[@]}"
    done
    "$fw" -w -C FORWARD -j DOCKER-USER 2>/dev/null || "$fw" -w -I FORWARD 1 -j DOCKER-USER
}

while true; do
    if addresses=$(for host in "${hosts[@]}"; do getent ahosts "$host" || exit 1; done) && [[ -n $addresses ]]; then
        refresh_allowlist mail-clients4 inet
        refresh_firewall_rules iptables mail-clients4
        refresh_allowlist mail-clients6 inet6
        refresh_firewall_rules ip6tables mail-clients6
    else
        echo "Hostname lookup failed; firewall unchanged (first run: protection not installed)." >&2
    fi
    sleep 24h
done