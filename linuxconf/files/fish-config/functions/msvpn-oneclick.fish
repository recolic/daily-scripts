function msvpn-oneclick
    set -l prev_ts 0
    set -l fail_count 0

    while true
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Redmond-WA --disable-ipv6 https://msftvpn-alt.ras.microsoft.com
        sudo -E gpclient --fix-openssl connect --browser microsoft-edge-stable --gateway Redmond --disable-ipv6 https://msftvpn-alt.ras.microsoft.com

        set -l now_ts (date +%s)

        if test $prev_ts -ne 0
            if test (math "$now_ts - $prev_ts") -lt 10
                set fail_count (math "$fail_count + 1")
            else
                set fail_count 0
            end
        end

        set prev_ts $now_ts
        sleep $fail_count; or break
    end
end

