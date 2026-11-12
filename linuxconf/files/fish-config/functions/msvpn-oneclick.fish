function msvpn-oneclick
    while true
        sudo -E gpclient connect --browser microsoft-edge-stable --gateway Redmond-WA https://msftvpn-alt.ras.microsoft.com
        sudo -E gpclient connect --browser microsoft-edge-stable --gateway Redmond    https://msftvpn-alt.ras.microsoft.com

        read -P "ENTER to reconnect, ctrl-C to break> "; or break
    end
end

