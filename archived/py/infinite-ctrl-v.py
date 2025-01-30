#!/usr/bin/env python3
# Use this script with https://recolic.net/phy and https://recolic.net/phy2 
#     to avoid typing fucked numbers into page by hand.
from pykeyboard import PyKeyboard
import time

k = PyKeyboard()
def _type():
    ### Start type_string
    k.press_key(k.control_l_key)
    k.tap_key('v')
    k.release_key(k.control_l_key)
    time.sleep(0.2)
    k.tap_key(k.enter_key)

print('You have 5 seconds to ready for auto-typing.')
time.sleep(5)


while True:
    _type()
    time.sleep(5)

