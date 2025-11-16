set p (rsec ProxySub_API)
set API_URLS "$p?2" "$p?3a"

for URL in $API_URLS
    echo "DOWNLOADING URL SUBS : $URL"

    curl -s "$URL" | base64 -d | dos2unix | while read -l line
        echo "DECODING: $line"
        echo "$line" | python vmess2json.py --inbounds socks:10808 -o output.json >/dev/null 2>&1

        if test -s output.json
            set name (python proxy-url-to-name.py "$line")
            mv output.json "$name.json"
        else
            echo "Skip invalid / unsupported URL"
        end
    end
end

