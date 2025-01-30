#!/usr/bin/env python3
import time
print('I\'ll rename all file in current directory in 5 seconds......')
time.sleep(5)
print('Launch!')

import shutil
import os
far = os.listdir()

for index, fl in enumerate(far):
    pos = fl.rfind('.')
    if pos == -1:
        newName = str(index)
    else:
        newName = str(index) + fl[pos:]
    shutil.move(fl, newName)
print('done.')    