#!/bin/bash

# Configure your qBitTorrent API endpoint. 
#   Enable it in Tools->Web UI->Web User Interface. By default, it's 127.0.0.1:8080. 
#   Usually, you want to enable 'bypass authentication for clients on localhost'. If you still want to set a 
#     password, just add `-u username:password` option to the curl command. 
api_endpoint="http://127.0.0.1:8080/api/v2"
# You can customize the blacklist keywords. 
blacklists=(
    "Xun[Ll]ei"
    "XL00"
    "^7\."
)

##############################################################

function curl_wrapped () {
    curl -s "$@" || echo "Warning: CURL $@ failed with error code $?" 1>&2
}

function show_mercy () {
    # not valid if qbittorrent is already running
    local conf_path="$HOME/.config/qBittorrent/qBittorrent.conf"
    [[ -f "$conf_path" ]] && sed -i 's/^BannedIPs=[, ]*[0-9a-f].*$/BannedIPs=/' "$conf_path"
}

echo "Unban all banned client, because IP might be reused by legit users... (valid only if qbittorrent is not running)"
show_mercy

echo "Checking all peers every 5 seconds..."
while true; do
    tasks=`curl_wrapped "$api_endpoint/sync/maindata?rid=0" | grep -oE '"[0-9a-f]{40}"' | tr -d '"' | sort | uniq`
    echo "$tasks" | while read -r line; do
        peers=`curl_wrapped "$api_endpoint/sync/torrentPeers?hash=$line&rid=0" | grep -o '"[^"]*":{"client":"[^"]*"'`
        echo "$peers" | while read -r peer; do
            ua=`echo "$peer" | sed 's/^.*"client":"//g' | sed 's/"$//g'`
            addr=`echo "$peer" | sed 's/":{"client.*$//g' | tr -d '"'`
            # echo "Checking $ua $addr"
            hit=0
            for pattern in "${blacklists[@]}"; do
                echo "$ua" | grep "$pattern" > /dev/null && hit=1
            done
            [[ $hit = 1 ]] && echo "[$(date)] Banning $addr because of his client '$ua'" || continue
            # Ban a peer
            # For qBitTorrent 4.5.x. Should be working for all versions
            curl_wrapped --data "peers=$addr" "$api_endpoint/transfer/banPeers"
            # For qBitTorrent 4.4.x
            # curl_wrapped "$api_endpoint/transfer/banPeers?peers=$addr"
        done
    done

    sleep 5
done
