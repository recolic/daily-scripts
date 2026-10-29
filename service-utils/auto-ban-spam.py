# created by GPT
from collections import Counter, deque
from datetime import datetime, timezone, timedelta
import ipaddress, re, subprocess, time
from pathlib import Path

INTERVAL = 60
LOG_FILE = Path("/var/log/nginx/access.log")
CONF = Path("/etc/nginx/banned_ips.conf")
POLICIES = [
    # condition in each policy has AND relationship.
    {"prefix": 32, "min_ips": 1, "requests_gt": 25, "req_per_min_gt": 120},
    {"prefix": 24, "min_ips": 2, "requests_gt": 20, "req_per_min_gt": 0},
    {"prefix": 24, "min_ips": 3, "requests_gt": 0, "req_per_min_gt": 0},
    {"prefix": 16, "min_ips": 3, "requests_gt": 20, "req_per_min_gt": 0},
    {"prefix": 16, "min_ips": 5, "requests_gt": 0, "req_per_min_gt": 0},
]


def extract_ip(line):
    m = re.match(r'^"([0-9]+(?:\.[0-9]+){3})', line.rsplit(" ", 1)[-1])
    try:
        return ipaddress.IPv4Address(m.group(1)) if m else None
    except ValueError:
        return None


def scan_access_log(log_path=LOG_FILE):
    time_prefix = (datetime.now(timezone.utc) - timedelta(minutes=1)).strftime("%Y-%m-%dT%H:%M:")
    req_per_min, ip_rpm = 0, Counter()
    graphql_ips, non_job_ips, tail_lines = deque(maxlen=100), deque(maxlen=100), deque(maxlen=100)
    with log_path.open("r", errors="replace") as f:
        for line in f:
            ip = extract_ip(line)
            if time_prefix in line:
                req_per_min += 1
                if ip:
                    ip_rpm[ip] += 1
            if "/api/graphql" in line and ip:
                graphql_ips.append(ip)
            if "/api/v4/jobs/request" not in line and ip:
                non_job_ips.append(ip)
            tail_lines.append((line, ip))
    path_ips = {}
    for line, ip in tail_lines:
        m = ip and re.search(r'"GET\s+([^\s?]+)', line)
        parts = [p for p in m.group(1).split("/") if p] if m else []
        if len(parts) >= 3:
            path_ips.setdefault(f"GET /{'/'.join(parts[:3])}/", set()).add(ip)
    return req_per_min, ip_rpm, Counter(graphql_ips), Counter(non_job_ips), path_ips


def find_violations(counts, ip_rpm):
    violations = set()
    for p in POLICIES:
        groups = {}
        for ip, count in counts.items():
            groups.setdefault(ipaddress.IPv4Network((ip, p["prefix"]), strict=False), {})[ip] = count
        for ips in groups.values():
            if len(ips) >= p["min_ips"] and sum(ips.values()) > p["requests_gt"] and sum(ip_rpm[ip] for ip in ips) > p["req_per_min_gt"]:
                violations.update(ips)
    return violations


def find_get_path_violations(path_ips, req_per_min):
    if req_per_min <= 200:
        return set()
    for k, ips in path_ips.items():
        print(f"[debug] {k} accessed by {len(ips)} IPs", flush=True)
    return {ip for ips in path_ips.values() if len(ips) > 50 for ip in ips}


def load_current_ban_list():
    try:
        ban_dict = {}
        for line in CONF.read_text().splitlines():
            entry, *comment = line.strip().split("#", 1)
            if entry.strip():
                ban_dict[ipaddress.IPv4Address(entry.strip().rstrip(";").split()[0])] = comment[0].strip() if comment else "manual"
        return ban_dict
    except Exception:
        return {}


def refresh_config(ban_dict):
    content = "".join(f"{ip} 1; # {reason}\n" for ip, reason in sorted(ban_dict.items()))
    if CONF.exists() and CONF.read_text() == content:
        return
    backup = CONF.read_text() if CONF.exists() else None
    try:
        CONF.write_text(content)
        subprocess.run(["nginx", "-t"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["systemctl", "reload", "nginx"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        CONF.write_text(backup) if backup is not None else CONF.unlink(missing_ok=True)
        raise


ban_dict = load_current_ban_list()
try:
    refresh_config(ban_dict)
except Exception:
    pass
while True:
    try:
        req_per_min, ip_rpm, cmd1_counts, cmd2_counts, path_ips = scan_access_log()
        for ips, reason in [(find_violations(cmd1_counts, ip_rpm), "cmd1"), (find_violations(cmd2_counts, ip_rpm), "cmd2"), (find_get_path_violations(path_ips, req_per_min), "multi-ip-get")]:
            for ip in ips:
                ban_dict.setdefault(ip, reason)
        reasons_str = ", ".join(f"{r}: {c}" for r, c in sorted(Counter(ban_dict.values()).items()))
        print(f"req/min: {req_per_min} Total bans: {len(ban_dict)} ({reasons_str})", flush=True)
        refresh_config(ban_dict)
    except Exception:
        pass
    time.sleep(INTERVAL)


