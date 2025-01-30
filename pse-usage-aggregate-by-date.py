

with open('1.csv') as f:
    c = f.read()

dhash = dict()

for line in c.split('\n'):
    if line == "":
        continue
    date, use = line.split(',')
    if date in dhash:
        dhash[date] += float(use)
    else:
        dhash[date] = float(use)

for k in dhash:
    print(k, dhash[k])

