#!/bin/bash

while true; do
    # Count the number of CLOSE_WAIT connections
    close_wait_count=$(netstat -n | grep -c CLOSE_WAIT)

    # Check if the count exceeds 32
    if [ "$close_wait_count" -gt 32 ]; then
        echo "$(date): Too many CLOSE_WAIT connections ($close_wait_count). Restarting frps service."
        systemctl restart frps
    else
        # echo "$(date): CLOSE_WAIT connections are under control ($close_wait_count). No action needed."
	:
    fi

    # Wait for 1 minute before the next check
    sleep 60
done

