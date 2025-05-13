#!/bin/python3 -u

import sys
if len(sys.argv) != 3:
    print("Usage: echo ANYTHING | simple-replace.py <from> <to>")
    exit(1)

from_, to = sys.argv[1], sys.argv[2]

i = sys.stdin.read()
print(i.replace(from_, to), end='')

