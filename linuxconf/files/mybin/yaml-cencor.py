#!/usr/bin/python3
import sys

if len(sys.argv) < 4:
    print('This program will remove all YAML top-level entry that matches the keyword. ')
    print('Usage: ./this.py yaml-path keyword dryrun?0/1')
    print('Usage: ./this.py ./test.yaml hello 1')
    print('Usage: ./this.py ./test.yaml _any_unicode 1')
    exit(0)

path, keyword, dryrun = sys.argv[1:]

with open(path, "r") as f:
    text = f.read()

forward = True
passed = []
entry_cache = []
drop = 0
for line in text.split('\n'):
    if line.startswith('- '):
        # A new entry
        if forward:
            passed += entry_cache
        else:
            drop += 1
            if dryrun == "1": print(entry_cache)
        entry_cache = []
        forward = True
    if keyword in line:
        forward = False
    if keyword == "_any_unicode" and not line.isascii():
        forward = False
    entry_cache.append(line)

print("{} lines passed, {} lines dropped. ".format(len(passed), drop))

if dryrun == "0":
    with open(path + ".backup", "w+") as f:
        print("Backup file at ", path + ".backup")
        f.write(text)
    
    with open(path, "w+") as f:
        f.write('\n'.join(passed) + '\n')
else:
    print("dryrun..")

