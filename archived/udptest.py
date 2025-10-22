#!/usr/bin/env python3
# GPT5
import sys, socket, time

IP = sys.argv[1]
PORT = 30000

if IP == "s":  # server mode
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("0.0.0.0", PORT))
    while True:
        data, addr = s.recvfrom(1024)
        print("Got:", data.decode(), "from", addr)
else:  # client mode
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    while True:
        s.sendto(b"hello", (IP, PORT))
        print("sent")
        time.sleep(1)

