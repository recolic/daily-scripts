import sys
import time
ilines = open(sys.argv[1]).read().split('\n')

freed = set()
leaked_lines = []
lptime = 0

for i, line in enumerate(ilines[::-1]):
    currtime = time.time()
    if currtime > lptime + 20:
        print(i, 'lines processed')
        lptime = currtime

    pos = line.find('PtP/SId=')
    if pos == -1:
        print('debug: bad line', line)
        continue
    ptr = line[pos+len('PtP/SId='):]
    if 'SxFreePortContext called' in line:
        freed.add(ptr)
    else:
        if ptr not in freed:
            leaked_lines.insert(0, ptr)

print('writeo')
open(sys.argv[1] + '.output', 'w+').write('\n'.join(leaked_lines))
print('freed ports: ', len(freed))







