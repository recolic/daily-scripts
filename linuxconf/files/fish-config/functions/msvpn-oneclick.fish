function msvpn-oneclick
    while true
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Redmond-WA --disable-ipv6 https://msftvpn-alt.ras.microsoft.com
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Redmond --disable-ipv6 https://msftvpn-alt.ras.microsoft.com

        read -P "ENTER to reconnect, ctrl-C to break> "; or break
    end
end

