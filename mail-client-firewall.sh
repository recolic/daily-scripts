#!/bin/bash
# created by GPT-6 Astra
# Run as root. Requires iptables, ip6tables, ipset and dig. For Docker bridge/NAT published ports.
# Port 25 stays unrestricted. DNS failures remove affected addresses until the next refresh.
set -euo pipefail
hosts=(www.recolic.cc git.recolic.cc proxy.recolic.cc storage.recolic.cc us1.896444.xyz jp3.896444.xyz sg2.896444.xyz)
ports=(465 587 110 995 143 993)

refresh_allowlist() {
    local name="$1" family="$2" type="$3" host ip
    ipset create "$name" hash:ip family "$family" -exist
    ipset create "$name-next" hash:ip family "$family" -exist
    ipset flush "$name-next"
    for host in "${hosts[@]}"; do
        while read -r ip; do
            ipset add "$name-next" "$ip" -exist
        done < <(dig +time=3 +tries=1 +noall +answer "$host" "$type" | awk -v type="$type" '$4 == type {print $5}')
    done
    ipset swap "$name-next" "$name"
    ipset destroy "$name-next"
}

refresh_firewall_rules() {
    local fw="$1" name="$2" port
    local -a rule
    "$fw" -w -S DOCKER-USER >/dev/null 2>&1 || "$fw" -w -N DOCKER-USER
    for port in "${ports[@]}"; do
        rule=(-p tcp -m conntrack --ctdir ORIGINAL --ctstatus DNAT --ctorigdstport "$port" -m set ! --match-set "$name" src -j DROP)
        "$fw" -w -C DOCKER-USER "${rule[@]}" 2>/dev/null || "$fw" -w -I DOCKER-USER 1 "${rule[@]}"
    done
    "$fw" -w -C FORWARD -j DOCKER-USER 2>/dev/null || "$fw" -w -I FORWARD 1 -j DOCKER-USER
}

while true; do
    refresh_allowlist mail-clients4 inet A
    refresh_firewall_rules iptables mail-clients4
    refresh_allowlist mail-clients6 inet6 AAAA
    refresh_firewall_rules ip6tables mail-clients6
    sleep 24h
done