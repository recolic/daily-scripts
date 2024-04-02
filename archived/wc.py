import fileinput

req=0
cr=0
lr=0

for line in fileinput.input():
    if line == '':
        continue
    if 'VFP request' in line:
        if 'client connect' in line:
            cr += 1
        if ' listen ' in line:
            lr += 1
        req += 1
    if 'Build' in line:
        print('accu req', req, 'cr', cr, 'lr', lr)
        req = 0
        cr = 0
        lr = 0



