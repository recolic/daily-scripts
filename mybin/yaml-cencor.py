#!/usr/bin/python3
import sys

if len(sys.argv) < 2:
    print('This program will remove all YAML top-level entry that matches the keyword. ')
    print('Usage: ./this.py yaml-path keyword')

path, keyword = sys.argv[1:]

with open(path, "r") as f:
    text = f.read()

forward = True
passed = []
drop = 0
for line in text.split('\n'):
    if line.startswith('- '):
        # A new entry
        forward = True
    if keyword in line:
        forward = False
    if forward:
        passed.append(line)
    else:
        drop += 1

print("{} lines passed, {} lines dropped. ".format(len(passed), drop))

with open(path + ".backup", "w+") as f:
    print("Backup file at ", path + ".backup")
    f.write(text)

with open(path, "w+") as f:
    f.write('\n'.join(passed))

