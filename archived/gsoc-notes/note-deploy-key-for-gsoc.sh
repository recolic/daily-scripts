#!/bin/bash

echo '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAu+kZtFLCLFDf1DztL3/M3V/d/9pYkLLbZ/zcHMH3UHtlzoLa
x
x
x
x
x
x
xxxxxxxxxxxxx
OxllBtsfJWyp485sn4YD/WT+C+hl4dYAlM8nE/QusC2JjyydBYjWMQ==
-----END RSA PRIVATE KEY-----
' > ./note-key &&
chmod go-rwx ./note-key &&
ssh-add ./note-key &&
git clone git@github.com:recolic/gsoc-notes.git
