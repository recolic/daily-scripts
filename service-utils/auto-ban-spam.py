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
    {"prefix": 32, "min_ips": 1, "req_per_min_gt": 120, "has_glcookie": False},
    {"prefix": 24, "min_ips": 2, "req_per_min_gt": 120, "has_glcookie": False},
    {"prefix": 24, "min_ips": 3, "req_per_min_gt":   0, "has_glcookie": False},
    {"prefix": 16, "min_ips": 3, "req_per_min_gt":  20, "has_glcookie": False},
    {"prefix": 16, "min_ips": 7,"req_per_min_gt":   0, "has_glcookie": False},
    {"prefix": 32, "min_ips": 1, "req_per_min_gt":  25, "is_graphql": True, "has_glcookie": False},
    {"prefix": 24, "min_ips": 3, "req_per_min_gt":  0, "is_graphql": True},
    {"prefix": 16, "min_ips": 7, "req_per_min_gt":  0, "is_graphql": True},
]


def extract_ip(line):
    m = re.match(r'^"([0-9]+(?:\.[0-9]+){3})', line.rsplit(" ", 1)[-1])
    try:
        return ipaddress.IPv4Address(m.group(1)) if m else None
    except ValueError:
        return None


def matches_policy(policy, is_graphql, has_glcookie):
    return all(policy.get(key) is None or policy[key] is value for key, value in (("is_graphql", is_graphql), ("has_glcookie", has_glcookie)))


def scan_access_log(log_path=LOG_FILE):
    time_prefix = (datetime.now(timezone.utc) - timedelta(minutes=1)).strftime("%Y-%m-%dT%H:%M:")
    req_per_min = 0
    policy_rpm = [Counter() for policy in POLICIES]
    tail_lines = deque(maxlen=100)
    with log_path.open("r", errors="replace") as f:
        for line in f:
            ip = extract_ip(line)
            tail_lines.append((line, ip))
            if time_prefix not in line:
                continue
            req_per_min += 1
            quoted_fields = line.split('"', 5)
            if ip and len(quoted_fields) == 6:
                request_parts = quoted_fields[1].split()
                request_path = request_parts[1].split("?", 1)[0] if len(request_parts) >= 2 else ""
                is_graphql = request_path == "/api/graphql"
                session_field = quoted_fields[4].strip()
                has_glcookie = {"gl=0": False, "gl=1": True}.get(session_field)
                if request_path != "/api/v4/jobs/request":
                    for policy, rpm in zip(POLICIES, policy_rpm):
                        if matches_policy(policy, is_graphql, has_glcookie):
                            rpm[ip] += 1
    path_ips = {}
    for line, ip in tail_lines:
        m = ip and re.search(r'"GET\s+([^\s?]+)', line)
        parts = [p for p in m.group(1).split("/") if p] if m else []
        if len(parts) >= 3:
            path_ips.setdefault(f"GET /{'/'.join(parts[:3])}/", set()).add(ip)
    return req_per_min, policy_rpm, path_ips


def find_violations(policy_rpm):
    violations = {}
    for policy_number, (p, ip_rpm) in enumerate(zip(POLICIES, policy_rpm)):
        groups = {}
        for ip, count in ip_rpm.items():
            groups.setdefault(ipaddress.IPv4Network((ip, p["prefix"]), strict=False), {})[ip] = count
        for ips in groups.values():
            if len(ips) >= p["min_ips"] and sum(ips.values()) > p["req_per_min_gt"]:
                for ip in ips:
                    violations.setdefault(ip, f"policy {policy_number}")
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
        req_per_min, policy_rpm, path_ips = scan_access_log()
        for ip, reason in find_violations(policy_rpm).items():
            ban_dict.setdefault(ip, reason)
        for ip in find_get_path_violations(path_ips, req_per_min):
            ban_dict.setdefault(ip, "multi-ip-get")
        reasons_str = ", ".join(f"{r}: {c}" for r, c in sorted(Counter(ban_dict.values()).items()))
        print(f"req/min: {req_per_min} Total bans: {len(ban_dict)} ({reasons_str})", flush=True)
        refresh_config(ban_dict)
    except Exception:
        pass
    time.sleep(INTERVAL)


