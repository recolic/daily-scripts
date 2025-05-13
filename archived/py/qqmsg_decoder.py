#!/usr/bin/env python3
# $ sqlite3 123123123-IndexQQMsg.db
# sqlite> .output /home/recolic/extraDisk/tmp/tmp.out
# sqlite> select * from IndexContent_content ;
# sqlite> .quit

import sys
import base64
import datetime

############## User defined
def _filter(line):
    #return '123123123' in line
    return True
##############

def decode_qtimestamp(s):
#    print('debug', s, file=sys.stderr)
    if s == '':
        return 0
    ts = base64.b64decode(s)[4:8]
    return sum([int(ts[i])*(256**(3-i)) for i in range(4)])

def timestamp_to_str(int_ts):
    return datetime.datetime.fromtimestamp(int_ts).strftime('%Y-%m-%d %H:%M:%S')

with open(sys.argv[1]) as f: 
    cont = f.read()

for line in cont.split('\n'):
    if line == '':
        continue
    ar = line.split('|')
    timestamp = timestamp_to_str(decode_qtimestamp(ar[-1]))
    ar = ar[:-1]
    line = '|'.join([ar[0]] + [base64.b64decode(ele.encode()).decode(errors='ignore') for ele in ar[1:]])
    line += '|' + timestamp
    if _filter(line):
        print(line)

