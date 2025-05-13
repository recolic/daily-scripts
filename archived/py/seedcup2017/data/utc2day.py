#!/bin/env python3
# convert utc time to day number. 
# One day is 03:30:00 to next half past 3.
#
# task: known day 0,1,2...31, forcast day 32,33,34

sec_per_day = 24*60*60
begin_day0 = 1501011000
end_day = 1503689400

def today(time):
    res = int((time-begin_day0)/sec_per_day)
    if res < 0 or res > 31:
        raise ValueError('Data out of range? {} to {}'.format(time, res))
    return res

def readBehaveDat():
    with open('behavior_info.txt', 'r') as fd:
        s=fd.read()
    dat = []
    for line in s.split('\n'):
        if line == '':
            continue
        try:
            dat.append([int(e) for e in line.split('\t')])
        except ValueError:
            print('line=', line)
            raise
    return dat

def writeBehaveDat(dat):
    s=''
    for datline in dat:
        line = "\t".join([str(i) for i in datline])
        s += line + '\n'
    with open('behavior_info.txt.modify', 'w+') as fd:
        fd.write(s)

dat = readBehaveDat()
for i in range(len(dat)):
    dat[i][2] = today(dat[i][2])
writeBehaveDat(dat)
