#!/usr/bin/env python3
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} KEY", file=sys.stderr)
    sys.exit(1)

prompt = f"[rsec] Need secret '{sys.argv[1]}'"

try:
    import tkinter as tk
    from tkinter import simpledialog
    root = tk.Tk()
    root.withdraw()
except Exception:  # Tk unavailable or no GUI display
    try:
        print(prompt + ": ", end="", file=sys.stderr, flush=True)
        secret = input()
    except (EOFError, KeyboardInterrupt):
        sys.exit(1)
else:
    secret = simpledialog.askstring("Secret", prompt, show="*", parent=root)
    root.destroy()

if not secret:
    sys.exit(1)

print(secret)

