#!/usr/bin/env python3
# GPT generated
import sys, hashlib

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} file password")
    sys.exit(1)

file, password = sys.argv[1], sys.argv[2]

# derive 1KB key from password (repeated hashing)
key = b""
seed = password.encode()
while len(key) < 1024:
    seed = hashlib.sha256(seed).digest()
    key += seed
key = key[:1024]

# read file
with open(file, "r+b") as f:
    block = f.read(1024)
    # XOR block with key
    transformed = bytes(a ^ b for a, b in zip(block, key))
    f.seek(0)
    f.write(transformed)

print("First 1KB transformed. Run again with same password to restore.")

