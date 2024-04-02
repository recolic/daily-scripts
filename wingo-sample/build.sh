#!/bin/bash
[[ "$1" = "" ]] && f=src.go || f="$1"
GOOS=windows GOARCH=amd64 go build -o test.exe "$f"
cp test.exe ~/tmp/
