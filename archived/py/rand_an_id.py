#!/bin/env python3

import string
import random

chars = string.ascii_uppercase + string.digits
lenA = 4
lenB = 4
length = lenA * lenB


def get_id():
    k = ''
    for i in range(length):
        k += random.choice(chars)
    k = '-'.join([k[i:i+lenA] for i in range(0, length, lenA)])
    return k

print(get_id())


