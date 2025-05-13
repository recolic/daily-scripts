#!/bin/bash
## Setup Guide:
## 1. Setup VM
# VM is fresh installed android-x86 + microsoft authenticator x86_64 apk + no-UEFI, need screen lock before setup msauth apk.
# qemu-system-x86_64 -drive file=/mnt/fsdisk/android-vm/android-msauth-x86-bios-pswd0000.qcow2,if=virtio -cpu host -smp 4 -m 4G --enable-kvm -net nic,model=virtio-net-pci -net user,hostfwd=tcp::25582-:5555 -vnc :18
# "stay awake" in developer options
## 2. Setup HTTPD (See the msauth-httpd source code below, build it with `go build xxx.go`)
## 3. Put this script in the workdir of httpd daemon, enjoy.

code="$1"
echo "$code" | grep '^[0-9][0-9]$' > /dev/null || ! echo "ERROR: Expect 2 digits input" || exit 1

if adb devices | grep localhost:25582 > /dev/null; then
    :
else
    adb connect localhost:25582
    adb devices | grep localhost:25582 || ! echo "ERROR ADB unable to connect" || exit 1
fi

sleep 2 ## Make sure code arrives
adb shell input text $code
sleep 0.5
adb shell input keyevent KEYCODE_ENTER
echo OK

## Make sure leftovers get cleaned up
nohup bash -c "sleep 15 ; adb shell input keyevent KEYCODE_ENTER" & disown

## msauth-httpd source code:
# cGFja2FnZSBtYWluCgppbXBvcnQgKAoJImZtdCIKCSJsb2ciCgkibmV0L2h0dHAiCgkib3MvZXhl
# YyIKCSJzdHJpbmdzIgopCgpmdW5jIGhhbmRsZVJlcXVlc3QodyBodHRwLlJlc3BvbnNlV3JpdGVy
# LCByICpodHRwLlJlcXVlc3QpIHsKCS8vIEV4dHJhY3QgdGhlIG51bWJlciBmcm9tIHRoZSByZXF1
# ZXN0IHBhdGgKCXBhdGggOj0gci5VUkwuUGF0aAoJbnVtU3RyIDo9IHN0cmluZ3MuVHJpbVByZWZp
# eChwYXRoLCAiLyIpCgludW0gOj0gc3RyaW5ncy5UcmltU3VmZml4KG51bVN0ciwgIi8iKQoKCS8v
# IFZhbGlkYXRlIGlmIHRoZSBudW1iZXIgaXMgdmFsaWQKCWlmIG51bSA9PSAiIiB7CgkJaHR0cC5F
# cnJvcih3LCAiSW52YWxpZCByZXF1ZXN0IGZvcm1hdCIsIGh0dHAuU3RhdHVzQmFkUmVxdWVzdCkK
# CQlyZXR1cm4KCX0KCgkvLyBFeGVjdXRlIHRoZSBzaGVsbCBzY3JpcHQgd2l0aCB0aGUgbnVtYmVy
# IGFzIGFuIGFyZ3VtZW50CgljbWQgOj0gZXhlYy5Db21tYW5kKCJiYXNoIiwgIm1zYXV0aC1hZGIt
# dHlwZS1jb2RlLnNoIiwgbnVtKQoJb3V0cHV0LCBlcnIgOj0gY21kLkNvbWJpbmVkT3V0cHV0KCkK
# CgkvLyBXcml0ZSB0aGUgc2NyaXB0IG91dHB1dCBhcyB0aGUgSFRUUCByZXNwb25zZQoJdy5IZWFk
# ZXIoKS5TZXQoIkNvbnRlbnQtVHlwZSIsICJ0ZXh0L3BsYWluIikKCWlmIGVyciAhPSBuaWwgewoJ
# CXcuV3JpdGVIZWFkZXIoaHR0cC5TdGF0dXNJbnRlcm5hbFNlcnZlckVycm9yKQoJCWZtdC5GcHJp
# bnRmKHcsICJTY3JpcHRSZXQ6ICV2XG4lcyIsIGVyciwgb3V0cHV0KQoJCXJldHVybgoJfQoKCXcu
# V3JpdGVIZWFkZXIoaHR0cC5TdGF0dXNPSykKCWZtdC5GcHJpbnRmKHcsICIlcyIsIG91dHB1dCkK
# fQoKZnVuYyBtYWluKCkgewoJLy8gUmVnaXN0ZXIgdGhlIGhhbmRsZXIgZm9yIGluY29taW5nIEhU
# VFAgcmVxdWVzdHMKCWh0dHAuSGFuZGxlRnVuYygiLyIsIGhhbmRsZVJlcXVlc3QpCgoJLy8gU3Rh
# cnQgdGhlIEhUVFAgc2VydmVyIG9uIGxvY2FsaG9zdDoyNTU4MwoJcG9ydCA6PSAiOjI1NTgzIgoJ
# Zm10LlByaW50ZigiU3RhcnRpbmcgc2VydmVyIG9uICVzXG4iLCBwb3J0KQoJaWYgZXJyIDo9IGh0
# dHAuTGlzdGVuQW5kU2VydmUocG9ydCwgbmlsKTsgZXJyICE9IG5pbCB7CgkJbG9nLkZhdGFsKCJT
# ZXJ2ZXIgZXJyb3I6IiwgZXJyKQoJfQp9Cgo=

