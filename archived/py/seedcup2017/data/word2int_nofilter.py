#!/bin/env python3


dic = {}
maxnum = -1

def word2int(word):
    global maxnum
    if word in dic:
        return dic[word]
    else:
        maxnum += 1
        dic[word] = maxnum
        return maxnum

def convLine(line):
    if line == '':
        return ''
    ar=line.split("\t")
    if len(ar) != 6:
        raise ValueError('bad data:'+line)
    ints = [word2int(wd) for wd in ar[4].split(' ') if len(wd) != 0]
    ar[4] = ' '.join([str(i) for i in ints])
    res = "\t".join(ar)
    return res

with open('product_info.txt', 'r') as fdin:
    with open('product_info.txt.modify', 'w+') as fdout:
        for line in fdin:
            fdout.write(convLine(line))
