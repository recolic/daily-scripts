#!/bin/sh
python3 /smsapi.py 30801 &
python3 /doorapi.py ## listens 30802

