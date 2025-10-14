function msvpn-oneclick
    while true
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Bay-CA --disable-ipv6 https://msftvpn-alt.ras.microsoft.com
        sleep 1
    end
end
