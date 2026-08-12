#!/usr/bin/env python3
# Similar to 'grep', but use "chunk" as unit.
# Chunk is a multiline text block separated by empty line.
# 
# windows CRLF supported.
## GPT 5.4
import sys
import re


def read_chunks(path):
    with open(path, "r", encoding="utf-8", errors="replace", newline=None) as f:
        content = f.read()

    # split on blank lines, handling \n and \r\n safely
    chunks = re.split(r'\r?\n\s*\r?\n', content)
    return [chunk.strip() for chunk in chunks if chunk.strip()]


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <keyword> [file]", file=sys.stderr)
        sys.exit(1)

    keyword = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) == 3 else "/dev/stdin"

    chunks = read_chunks(path)

    found = False
    for chunk in chunks:
        if keyword in chunk:
            print(chunk)
            print()
            found = True

    if not found:
        sys.exit(1)


if __name__ == "__main__":
    main()

