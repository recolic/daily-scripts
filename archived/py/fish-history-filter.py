
fname = 'fish_history'

def banned(line):
    keywords = []
    for keyword in keywords:
        if keyword in line.lower():
            return True
    return False

with open(fname, 'rb') as f:
    cont = f.read().decode('utf-8', 'ignore')

output_buf = []
section_buf = []
section_good = True
for line in cont.split('\n'):
    if line.startswith('- cmd:'):
        if section_good:
            output_buf += section_buf
        section_good = True
        section_buf = []
    section_good = section_good and not banned(line)
    section_buf += [line]

with open(fname+'.out', 'w+') as f:
    f.write('\n'.join(output_buf))





