#!/usr/bin/env python3

import requests
import hashlib
import datetime

server_uri = 'https://api.recolic.net/keepalive.php'

hostname = 'RECOLICPC'
hostid = '1111-1111-1111-1111'
salt = 'RECOLIC_KEEPALIVE_ST'

def make_checksum():
    m = hashlib.sha384()
    m.update((hostid + datetime.datetime.utcnow().strftime("%m%d%H") + salt).encode())
    return str(m.hexdigest())
checksum = make_checksum()
print(checksum)

payload = {'name': hostname, 'token': checksum}
r = requests.post(server_uri, data=payload)

if r.status_code != 200:
    print('Failed http request. (returned {}:{})'.format(r.status_code, r.text))
    exit(2)
