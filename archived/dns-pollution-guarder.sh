#!/bin/bash

function restart_router_dnsmasq () {
	echo $(date)': dns request failed. checking again.'
	# confirm again!
	drill @10.100.100.10 test.1111.recolic.net A | grep test.1111.recolic.net. | grep -F '1.1.1.1'	&& return 0

	echo $(date)': confirmed accident. restart router dnsmasq.'
	ssh root@10.100.100.10 /etc/init.d/dnsmasq restart
}

echo $(date)': guarding... (check per 2 minutes)'
while true; do
	drill @10.100.100.10 test.1111.recolic.net A | grep test.1111.recolic.net. | grep -F '1.1.1.1'	 > /dev/null
	ret=$?

	[[ $? != 0 ]] && restart_router_dnsmasq
	[[ "_$firstEcho" = "_" ]] && firstEcho=false && echo $(date)' first check passed. supress further success info...'
	sleep 121 # 2min TTL
done


