#!/bin/env python3
'''
Convert Swithy rule list to fit FoxyProxy(firefox) Format.
'''


import json

jdata = []

with open('white.list', 'r') as f:
    ar=f.read().split('\n')
    for url in ar:
        if url == '' or url[0] != '*':
            continue
        jdata.append({"enabled":True,"name":"","pattern":url,"isRegEx":False,"caseSensitive":False,"blackList":True,"multiLine":False})

print(json.dumps({"patterns":jdata}))
