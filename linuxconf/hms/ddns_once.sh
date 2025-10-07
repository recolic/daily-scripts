router_pub_ip=$(sshpass -p $(rsec genpasswd_10.100.100.1) ssh -o StrictHostKeyChecking=no root@10.100.100.1 ip a | grep 'scope global wan' | cut -d / -f 1 | sed 's/^.* //')
curl -s "https://dynamicdns.park-your-domain.com/update?host=rhome&domain=896444.xyz&password=$(rsec DDNS_XYZ_TOKEN)&ip=$router_pub_ip"
