sudo udp2raw -c -l 0.0.0.0:9988 -r 34.80.72.2:9988 -k PASSWORD_PLACEHOLDER___ -a &
sleep 10
sudo openvpn tw.ovpn &

sleep 10
sudo ip r add 34.80.72.2 via 192.168.42.129 dev enp0s20f0u1

sudo create_ap wlp1s0 tun0 Recolic_USA_Endpoint PASSWORD_PLACEHOLDER___
