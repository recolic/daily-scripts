# created by GPT
import sys

with open(sys.argv[1]) as a, open(sys.argv[2]) as b:
    A, B = set(a.read().splitlines()), set(b.read().splitlines())
print(f"common={len(A & B)}, uniqA={len(A - B)}, uniqB={len(B - A)}")
