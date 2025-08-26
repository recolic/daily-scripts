#!/usr/bin/env python3
import requests

# Hardcoded server details
URL = "http://192.168.1.123:30405/"  # replace with your board's address
TOKEN = "abc"  # must match the Go server's token

def main():
    print("Connected to remote shell at", URL)
    while True:
        try:
            cmd = input("> ")
        except EOFError:
            break
        if not cmd.strip():
            continue
        if cmd.lower() in ("exit", "quit"):
            break

        try:
            resp = requests.post(URL, headers={"token": TOKEN}, data=cmd.encode("utf-8"), timeout=999)
            print(resp.text, end="")
        except Exception as e:
            print("Error:", e)

if __name__ == "__main__":
    main()

