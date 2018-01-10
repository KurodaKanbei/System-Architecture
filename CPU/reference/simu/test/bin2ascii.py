#!/usr/bin/env python
# based on Lequn Chen's Code
import os
import sys
import binascii

INPUT = 'example.bi'
OUTPUT = 'test.in'

s = open(INPUT, 'rb').read()
s = binascii.b2a_hex(s)
with open(OUTPUT, 'w') as f:
    for i in range(0, len(s), 8):
        f.write(s[i:i+8])
        f.write('\n')
