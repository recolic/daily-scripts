#!/usr/bin/env python3

import requests
import hashlib
import datetime

server_uri = 'https://api.recolic.net/keepalive.php'

hostname = 'master.dl.recolic.net'
hostid = ''
testuri = 'https://dl.recolic.net'
salt = 'RECOLIC_KEEPALIVE_ST'

def isalive():
    return requests.request('GET', testuri).status_code == 200

if not isalive():
    print('Broken service. skipped request.')
    exit(3)

def make_checksum():
    m = hashlib.sha384()
    m.update((hostid + datetime.datetime.utcnow().strftime("%m%d%H") + salt).encode())
    return str(m.hexdigest())
checksum = make_checksum()

payload = {'name': hostname, 'token': checksum}
r = requests.post(server_uri, data=payload)

if r.status_code != 200:
    print('Failed http request. (returned {}:{})'.format(r.status_code, r.text))
    exit(2)
