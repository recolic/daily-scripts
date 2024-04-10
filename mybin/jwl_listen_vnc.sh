#!/bin/bash

while true; do
    x11vnc -passwd "$R_SEC_WEAK10" -forever -shared # -viewonly
done

