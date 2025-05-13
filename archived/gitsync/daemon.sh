#!/bin/bash

while true; do
	echo "[$(date)] Calling sync scrilpt:"
	./dosync.sh
	sleep 600
done
