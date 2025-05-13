#!/bin/env python3


dic_id = {}
dic_times = {}
maxnum = -1
dry_run = True

def word2int(word):
    global maxnum, dry_run, dic_id, dic_times
    if not dry_run:
        if word in dic_id:
            return dic_id[word]
    else:
        if word in dic_times:
            dic_times[word] += 1
            if dic_times[word] == 10: # if word appears less than 10 times, it's ommited.
                maxnum += 1
                dic_id[word] = maxnum
        else:
            dic_times[word] = 0
        return 0

def convLine(line):
    global maxnum
    if line == '':
        return ''
    ar=line.split("\t")
    if len(ar) != 6:
        raise ValueError('bad data:'+line)
    ints = [word2int(wd) for wd in ar[4].split(' ') if len(wd) != 0]
    ints = [i for i in ints if i != None]
    if len(ints) == 0 and not dry_run:
        print('warning: empty line after filter.', line)
        maxnum += 1
        ints=[maxnum]
        #return 'ERROR_EMPTY_LINE'
    ar[4] = ' '.join([str(i) for i in ints])
    res = "\t".join(ar)
    return res

with open('product_info.txt', 'r') as fdin:
    with open('product_info.txt.modify', 'w+') as fdout:
        for line in fdin:
            convLine(line)
dry_run = False
with open('product_info.txt', 'r') as fdin:
    with open('product_info.txt.modify', 'w+') as fdout:
        for line in fdin:
            fdout.write(convLine(line))

print('maxnum is {}.'.format(maxnum))
