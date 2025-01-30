#!/usr/bin/env python3
# php passes arg to server.py.

import sys
import hashlib
import datetime
import filelock

status_file = './status'
salt = 'RECOLIC_KEEPALIVE_ST'
offline_time = datetime.timedelta(minutes=5) # 5 minutes.

name_and_id = {
    'RECOLICPC': 'MSJ8-2YO5-663J-E4RW',
    'RECOLICMPC': '25QJ-47E0-F1IX-ZSHY',
    'www.recolic.net': 'X74H-GKB8-0UTB-K6JQ',
    'jump.recolic.net': 'U97U-0OLN-WVNI-O2UN',
    'ss.recolic.net': '04CP-AVIH-SUIH-YBP3',
    'drive.recolic.net': '7RUG-X74I-86GQ-QM61',
    'master.dl.recolic.net': 'CDND-27RM-EJB1-G2F8',
    'master.tdl.recolic.net': '9K68-JDKE-650S-CUUP'
}

if len(sys.argv) < 3:
    print('Args: ./server.py HOSTNAME CHECKSUM')
    exit(1)

def host_name2id(hostname):
    return name_and_id[hostname]

def check_checksum(hostname, checksum):
    m = hashlib.sha384()
    m.update((host_name2id(hostname) + datetime.datetime.utcnow().strftime("%m%d%H") + salt).encode())
    return checksum == str(m.hexdigest())

''' status file:
#hostname last-update status
RECOLICPC 2017-01-01_00:01:53 online
RECOLICMPC 2016-12-31_09:53:22 offline
...
'''
def get_currtime_text():
    return datetime.datetime.utcnow().strftime("%Y-%m-%d_%H:%M:%S")
def is_outoftime(timetext):
    time_tocheck = datetime.datetime.strptime(timetext, "%Y-%m-%d_%H:%M:%S")
    time_current = datetime.datetime.utcnow()
    return time_tocheck + offline_time < time_current
def update_db(hostname):
    with open(status_file, 'r') as fd:
        origin = fd.read()
    must_creat = True
    new = []
    for line in origin.split('\n'):
        if len(line) == 0 or line[0] == '#':
            continue # Comment or empty line.
        ar = line.split(' ')
        if len(ar) != 3:
            print('Warning: broken line `{}` ignored in status_file.'.format(line))
            continue # Broken line.
        ### Check if is turning to offline
        if ar[2] == 'online' and is_outoftime(ar[1]):
            ar[2] = 'offline'
        if hostname == ar[0]: # update host status
            must_creat = False
            ar[1] = get_currtime_text()
            ar[2] = 'online'
        new.append(' '.join(ar))
    if must_creat:
        new.append(' '.join([hostname, get_currtime_text(), 'online']))
    with open(status_file, 'w+') as fd:
        fd.writelines([line+'\n' for line in new])
def locked_update_db(hostname):
    lock = filelock.FileLock('/tmp/alive_server.lock')
    with lock.acquire(timeout = 3):
        update_db(hostname)

print(get_currtime_text(), sys.argv[1], sys.argv[2])
if check_checksum(sys.argv[1], sys.argv[2]):
    locked_update_db(sys.argv[1])
else:
    print('Invalid checksum.')
    exit(3)
