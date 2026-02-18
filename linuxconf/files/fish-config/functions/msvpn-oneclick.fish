function msvpn-oneclick
    while true
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Beijing-CN --disable-ipv6 https://msftvpn-alt.ras.microsoft.com

        # tmp: global VPN
        sudo ip r add default dev tun0  metric 98
        echo -e "nameserver 10.50.10.50\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf

        sleep 1 ; or break
    end
end
