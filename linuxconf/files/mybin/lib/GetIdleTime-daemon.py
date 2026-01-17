# Better GetIdleTime for gnome.
# This script runs as a daemon, constantly reporting GetIdleTime.
# Safe against sudden notification event. It won't be reset even if gnome GetIdleTime went back to zero.
#
# Must run as normal user on login, otherwise dbus won't work.

import subprocess
import time
import re
from collections import deque

POLL_INTERVAL = 1000 # ms
BUF_SIZE = 3600  # 1 hour

IDLE_CMD = [
    "gdbus", "call",
    "--session",
    "--dest", "org.gnome.Mutter.IdleMonitor",
    "--object-path", "/org/gnome/Mutter/IdleMonitor/Core",
    "--method", "org.gnome.Mutter.IdleMonitor.GetIdletime"
]

idle_re = re.compile(r"\(uint64 (\d+),\)")
datapoints = deque(maxlen=BUF_SIZE)

def fetch_idle_time():
    # returns ms
    try:
        out = subprocess.check_output(IDLE_CMD, stderr=subprocess.DEVNULL, text=True)
        m = idle_re.search(out)
        return int(m.group(1)) if m else 1
    except Exception as e:
        print(e)
        return 1


def is_active(dp):
    return dp < POLL_INTERVAL


def find_last_absolute_active(datapoints):
    last_idx = 0
    n = len(datapoints)
    dps = list(datapoints)

    # window = 4, all active
    for i in range(n - 3):
        if all(is_active(dp) for dp in dps[i:i + 4]):
            last_idx = i + 3

    # window = 8, >=4 active
    for i in range(n - 7):
        if sum(is_active(dp) for dp in dps[i:i + 8]) >= 4:
            last_idx = max(last_idx, i + 7)

    return last_idx


def adjustedIdleTime(datapoints):
    last_idx = find_last_absolute_active(datapoints)

    Na = Ni = 0
    dps = list(datapoints)

    if last_idx >= 0:
        for dp in dps[last_idx + 1:]:
            if dp is None:
                continue
            if is_active(dp):
                Na += 1
            else:
                Ni += 1

    res = POLL_INTERVAL * max(0, Ni - Na)
    print(f"DEBUG: Na={Na} Ni={Ni} last_idx={last_idx} adjustedIdleTime={res}")
    return res

print("Writing status file: /tmp/.idled-py-out ...")
while True:
    datapoints.append(fetch_idle_time())

    adj = adjustedIdleTime(datapoints)
    with open("/tmp/.idled-py-out", "w+") as f:
        f.write(str(adj))

    time.sleep(POLL_INTERVAL/1000)

