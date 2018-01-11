import os
import sys
import binascii

INPUT = "instruction.bin"
OUTPUT = "instr.bin"

s = open(INPUT, 'rb').read()
s = binascii.b2a_hex(s)
with open(OUTPUT, 'w') as f:
    for i in range(0, len(s), 8):
        f.write(str(s[i:i + 8]))
        f.write('\n')
