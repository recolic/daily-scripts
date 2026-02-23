function msvpn-oneclick
    while true
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Beijing-CN --disable-ipv6 https://msftvpn-alt.ras.microsoft.com

        # tmp: global VPN
        # sudo resolvectl dns tun0 10.50.10.50
        # sudo resolvectl domain tun0 "~corp.microsoft.com"
        # sudo resolvectl default-route tun0 yes
        # sudo ip r add default dev tun0  metric 98

        sleep 1 ; or break
        if grep 1 /tmp/gpexit 2> /dev/null
            break
        end
    end
end
