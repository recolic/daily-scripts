#!/bin/bash

while true; do
    #arecord -f cd -D sysdefault:CARD=Loopback | nc base.cn1.recolic.org 5906
    arecord -f cd -D default | nc base.cn1.recolic.org 5906
    [[ $? = 127 ]] && break
done
exit $?

