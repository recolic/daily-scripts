#!/usr/bin/env python3
# GPT5
import sys, socket, time, threading

IP = sys.argv[1]
PORT = 30001

if IP == "s":  # server mode
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("0.0.0.0", PORT))
    while True:
        data, addr = s.recvfrom(1024)
        print("Got:", data.decode(), "from", addr)
        s.sendto(b"world", addr)
else:  # client mode
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    def sender():
        while True:
            s.sendto(b"hello", (IP, PORT))
            time.sleep(1)
    threading.Thread(target=sender, daemon=True).start()

    while True:
        data, addr = s.recvfrom(1024)
        print("Reply:", data.decode(), "from", addr)
