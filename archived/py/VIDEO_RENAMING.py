#!/usr/bin/python3
# naming rule:
# fname := uniqueID  '_'  class  quality  '.avi'
#   class := 'L' | 'G'
############luo####good leg######
#   quality := 'L' | 'M' | 'H'
###############low##medium#high##
#   uniqueID is a arbitary unique string. This script can re-build the uniqueID.

import sys, os
import os.path

dest_prefix = sys.argv[-1]
postfix = 'avi'

files = sys.argv[1:-1]
counter = 0

def find_level_from_filename(f):
    pos = f.find('_')
    if pos == -1:
        return ''
    pos2 = f.find('.' + postfix, pos)
    if pos2 == -1:
        return ''
    return f[pos:pos2]

toRename = []

for fl in files:
    level = find_level_from_filename(fl)
    dest = dest_prefix + '{0:04d}'.format(counter) + level + '.' + postfix
    print('{} -> {}'.format(fl, dest))
    if os.path.isfile(dest):
        print('Error: {} already exists.'.format(dest))
        exit(1)
    toRename.append((fl, dest))
    counter += 1

print('Commit the change ? (y/N)')
confirm = input()

if not (confirm == 'y' or confirm == 'Y'):
    exit(2)

for pair in toRename:
    fl, dest = pair
    print('Commiting {} -> {}'.format(fl, dest))
    if os.path.isfile(dest):
        print('Error: {} already exists.'.format(dest))
        exit(1)
    os.rename(fl, dest)



