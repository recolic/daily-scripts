#!/usr/bin/env python3

import urllib3
import hashlib
import datetime

server_uri = 'https://api.recolic.net/keepalive.php'

hostname = 'ss.recolic.net'
hostid = '04CP-AVIH-SUIH-YBP3'
salt = 'RECOLIC_KEEPALIVE_ST'

def make_checksum():
    m = hashlib.sha384()
    m.update((hostid + datetime.datetime.utcnow().strftime("%m%d%H") + salt).encode())
    return str(m.hexdigest())
checksum = make_checksum()

http = urllib3.PoolManager()
payload = {'name': hostname, 'token': checksum}
r = http.request('POST', server_uri, fields=payload)
#r = requests.post(server_uri, data=payload)

if r.status != 200:
    print('Failed http request. (returned {}:{})'.format(r.status, r.data.decode('utf-8')))
    exit(2)

