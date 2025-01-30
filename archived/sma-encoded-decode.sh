#!/bin/bash

while IFS=$'\n' read -r line; do
    echo "$line" | base64 -d | gzip -d | grep .
done





