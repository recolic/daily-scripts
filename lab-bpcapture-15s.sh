#!/bin/bash
rm -f /tmp/1.pcap
backplane-ctl capture file /tmp/1.pcap
backplane-ctl capture start all
sleep 15
backplane-ctl capture stop all

