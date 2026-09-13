#!/bin/sh
# created by GPT-6 Astra
# Run: sh build.sh. Requires Go 1.22+; dependencies are downloaded automatically.
set -eu
cd -- "$(dirname -- "$0")"
export CGO_ENABLED=0 GOARCH=amd64
GOOS=linux go build -trimpath -ldflags='-s -w' -o smart-unzip-linux-amd64.out .
GOOS=windows go build -trimpath -ldflags='-s -w' -o smart-unzip-windows-amd64.exe .
printf '%s\n' 'Built smart-unzip-linux-amd64.out and smart-unzip-windows-amd64.exe'
