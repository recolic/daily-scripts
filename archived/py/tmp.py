import os
ostream = os.popen('find /var/www/data/ctest2 -name \'U201614531-*\'')
ostr = ostream.read()
oarr = ostr.split('\n')
for ele in oarr:
    if ele == '':
        continue

