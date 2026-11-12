#!/bin/bash
# created by GPT-5.6
set -euo pipefail
export LC_ALL=C
# Group totals include only explicit packages; multiple-group packages use their first group.
pacman -Qei | python3 -c '
import sys

units = ("B", "KiB", "MiB", "GiB", "TiB")
def size(value):
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.2f}{unit}"
        value /= 1024

groups, entries = {}, []
for record in sys.stdin.read().strip().split("\n\n"):
    if not record.strip():
        continue
    fields = dict((key.strip(), value.strip()) for line in record.splitlines() for key, sep, value in [line.partition(":")] if sep)
    name = fields["Name"]
    amount, unit = fields["Installed Size"].split()
    value = float(amount) * 1024 ** units.index(unit)
    group = fields["Groups"].split()[0]
    if group == "None":
        entries.append((value, name, []))
    else:
        groups.setdefault(group, []).append((value, name))
entries.extend((sum(value for value, name in members), group, members) for group, members in groups.items())
for value, name, members in sorted(entries, key=lambda entry: (-entry[0], entry[1])):
    print(f"{name}\t{size(value)}")
    for member_value, member_name in sorted(members, key=lambda member: (-member[0], member[1])):
        print(f"- {member_name}\t{size(member_value)}")
'
