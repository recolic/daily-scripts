#!/usr/bin/env python3
# Use this script with https://recolic.net/phy and https://recolic.net/phy2 
#     to avoid typing fucked numbers into page by hand.
from pykeyboard import PyKeyboard
import time

def virtual_type_array(arrToType, noWait=False):
    k = PyKeyboard()
    if not noWait:
        print('You have 5 seconds to ready for auto-typing.')
        time.sleep(5)
    for d in arrToType:
        k.type_string(str(d))
        k.tap_key(k.tab_key)

def type_string_with_enter_and_tab(pykb_instance, s):
    k = pykb_instance
    is_firstline = True
    for line in str(s).split('\n'):
        line = line.replace('\r', '')
        if is_firstline:
            is_firstline = False
        else:
            k.tap_key(k.enter_key)

        is_firstcol = True
        for column in line.split('\t'):
            if is_firstcol:
                is_firstcol = False
            else:
                k.tap_key(k.tab_key)
            k.type_string(column)



def _type(s):
    k = PyKeyboard()
    print('You have 5 seconds to ready for auto-typing.')
    time.sleep(5)

    ### Start type_string
    type_string_with_enter_and_tab(k, str(s))

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        _type(sys.argv[1])
    else:
        print('Reading stdin until EOF...')
        _type(sys.stdin.read())

