#!/bin/env python3

import numpy

def mark():
    print('program is here.')

with open('behavior_info.txt', 'r') as fd:
    s=fd.read()
mark()
dat = []
for line in s.split('\n'):
    if line == '':
        continue
    try:
        dat.append([int(e) for e in line.split('\t')])
    except ValueError:
        print('line=', line)
        raise
mark()

#dat = numpy.matrix(dat)

user_to_trace = [line[1] for line in dat if line[3] >= 3]
mark()

dat.sort(key=lambda l: l[2])
dat.sort(key=lambda l: l[0])
mark()
hold = -1
for line in dat:
    if line[0] == hold:
        print(line)
    else:
        # slow here, but doesn't matter.
        if line[0] in user_to_trace:
            hold = line[0]
            print(line)

