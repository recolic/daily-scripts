#!/bin/bash

while true; do
    x11vnc -passwd "$(rsec WEAK10)" -forever -shared # -viewonly
done

