#!/usr/bin/env python
# Designed for recolic.net

import sys

if len(sys.argv) < 2:
    print('Usage: python highlighter.py code.cpp')
    exit(127)

path=sys.argv[1]
with open(path,'r') as fd:
    cont=fd.read()

lastpos=0
pos=0
dealedCont=''
while True:
    pos = cont.find('<',pos+1)
    if pos == -1:
        break
    if cont[pos+1] != ' ':
        dealedCont+=cont[lastpos:pos+1]
        dealedCont+=' '
        lastpos=pos+1
dealedCont += cont[lastpos:]

with open(path+'.html','w+') as fd:
    fd.write("<html><head><link rel='stylesheet' href='/resource/default.min.css'><script src='/resource/highlight.min.js'></script><script>hljs.initHighlightingOnLoad();</script></head><body><pre><code>")
    fd.write(dealedCont);
    fd.write('</code></pre></body></html>')
