# created by GPT
import ipaddress
import re
import subprocess
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path


INTERVAL = 60
CONF = Path("/etc/nginx/banned_ips.conf")
COMMAND1 = "grep /api/graphql /var/log/nginx/access.log                  | tail -n100 | grep '[^ ]*$' -o | grep '\"[0-9]*.[0-9]*.[0-9]*.[0-9]*' -o | tr -d '\"' | sort | uniq -c | sort -h"
COMMAND2 = "cat /var/log/nginx/access.log | grep -v /api/v4/jobs/request | tail -n100 | grep '[^ ]*$' -o | grep '\"[0-9]*.[0-9]*.[0-9]*.[0-9]*' -o | tr -d '\"' | sort | uniq -c | sort -h"
POLICIES = [
    # condition in each policy has AND relationship.
    {"prefix": 32, "min_ips": 1, "requests_gt": 25, "global_req_per_min_gt": 120},
    {"prefix": 24, "min_ips": 2, "requests_gt": 20, "global_req_per_min_gt": 0},
    {"prefix": 24, "min_ips": 3, "requests_gt": 0, "global_req_per_min_gt": 0},
    {"prefix": 16, "min_ips": 3, "requests_gt": 20, "global_req_per_min_gt": 0},
    {"prefix": 16, "min_ips": 5, "requests_gt": 0, "global_req_per_min_gt": 0},
]


def read_req_per_min():
    prev_min_utc = datetime.now(timezone.utc) - timedelta(minutes=1)
    time_prefix = prev_min_utc.strftime("%Y-%m-%dT%H:%M:")
    result = subprocess.run(["grep", "-c", time_prefix, "/var/log/nginx/access.log"], capture_output=True, text=True)
    if result.returncode not in (0, 1):
        raise RuntimeError(f"Grep req/min failed ({result.returncode}): {result.stderr.strip()}")
    return int(result.stdout.strip()) if result.returncode == 0 and result.stdout.strip() else 0


def read_counts(cmd):
    result = subprocess.run(["bash", "-o", "pipefail", "-c", cmd], capture_output=True, text=True)
    if result.returncode not in (0, 1) or result.stderr:
        raise RuntimeError(f"Log command failed ({result.returncode}): {result.stderr.strip()}")
    counts = {}
    for line in result.stdout.splitlines():
        count, address = line.split()
        counts[ipaddress.IPv4Address(address)] = int(count)
    return counts


def find_violations(counts, req_per_min):
    violations = set()
    for policy in POLICIES:
        if req_per_min <= policy["global_req_per_min_gt"]:
            continue
        groups = {}
        for address, count in counts.items():
            network = ipaddress.IPv4Network((address, policy["prefix"]), strict=False)
            groups.setdefault(network, {})[address] = count
        for addresses in groups.values():
            if len(addresses) >= policy["min_ips"] and sum(addresses.values()) > policy["requests_gt"]:
                violations.update(addresses)
    return violations


def find_get_path_violations(req_per_min):
    if req_per_min <= 200:
        return set()
    result = subprocess.run(["tail", "-n100", "/var/log/nginx/access.log"], capture_output=True, text=True)
    if result.returncode != 0:
        return set()
    path_ips = {}
    for line in result.stdout.splitlines():
        match = re.search(r'"GET\s+([^\s]+)', line)
        if not match:
            continue
        url_path = match.group(1).split("?")[0]
        parts = [p for p in url_path.split("/") if p]
        if len(parts) < 3:
            continue
        identifier = "GET /" + "/".join(parts[:3]) + "/"
        ip_matches = re.findall(r'[0-9]+(?:\.[0-9]+){3}', line)
        if not ip_matches:
            continue
        ip_str = ip_matches[-1]
        try:
            ip = ipaddress.IPv4Address(ip_str)
            path_ips.setdefault(identifier, set()).add(ip)
        except ValueError:
            pass
    violations = set()
    for identifier, ips in path_ips.items():
        print(f"[debug] {identifier} accessed by {len(ips)} IPs", flush=True)
        if len(ips) > 50:
            violations.update(ips)
    return violations


def load_current_ban_list():
    try:
        ban_dict = {}
        for line in CONF.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("#", 1)
            entry = parts[0].strip().rstrip(";")
            reason = parts[1].strip() if len(parts) > 1 else "manual"
            if not entry:
                continue
            ip = entry.split()[0]
            ban_dict[ipaddress.IPv4Address(ip)] = reason
        return ban_dict
    except Exception:
        return {}


def refresh_config(ban_dict):
    content = "".join(f"{address} 1; # {reason}\n" for address, reason in sorted(ban_dict.items()))
    if CONF.exists() and CONF.read_text() == content:
        return
    backup = CONF.read_text() if CONF.exists() else None
    try:
        CONF.write_text(content)
        subprocess.run(["nginx", "-t"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["systemctl", "reload", "nginx"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        if backup is not None:
            CONF.write_text(backup)
        elif CONF.exists():
            CONF.unlink()
        raise


def add_violations(ip_batch, reason_str):
    for ip in ip_batch:
        ban_dict.setdefault(ip, reason_str)


ban_dict = load_current_ban_list()
try:
    refresh_config(ban_dict)
except Exception:
    pass
while True:
    try:
        req_per_min = read_req_per_min()
        add_violations(find_violations(read_counts(COMMAND1), req_per_min), "cmd1")
        add_violations(find_violations(read_counts(COMMAND2), req_per_min), "cmd2")
        add_violations(find_get_path_violations(req_per_min), "multi-ip-get")
        counts_by_reason = {}
        for r in ban_dict.values():
            counts_by_reason[r] = counts_by_reason.get(r, 0) + 1
        reasons_str = ", ".join(f"{r}: {c}" for r, c in sorted(counts_by_reason.items()))
        print(f"req/min: {req_per_min} Total bans: {len(ban_dict)} ({reasons_str})", flush=True)
        refresh_config(ban_dict)
    except Exception:
        pass
    time.sleep(INTERVAL)


