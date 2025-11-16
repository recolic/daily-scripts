#!/usr/bin/fish
# v1.05.202511

set script_dir (dirname (status --current-filename))
function download_subs
    ## Put your subscription url here, like this:
    # set SUB_URLS "https://example.com/sub/api?key=12345" "https://backup.com/dumb?user=trump" ...
    set p (rsec ProxySub_API)
    set SUB_URLS "$p?2" "$p?3a"
    
    for URL in $SUB_URLS
        echo "DOWNLOAD SUBS : $URL"
        curl -s "$URL" | base64 -d | dos2unix | while read -l line
            set name (python $script_dir/lib/proxy-url-to-name.py "$line")
            and echo "$name $line"
        end
    end
end
function get_vconfig_from_subs
    set node $argv[1]
    set port $argv[2]
    set in_cachefile $argv[3]
    set out_vconfigfile $argv[4]
    grep "^$node " $in_cachefile | sed "s|^$node ||" | python $script_dir/lib/vmess2json.py --inbounds "socks:$port" -o "$out_vconfigfile"
        or return 1
end

## Optional: prefer to run shadowsocks in native implementation
type -q ss-local ; and set ss ss-local ; or set ss sslocal
function vconfig_ss_available
    type -q $ss ; and type -q json2table ; and grep 'protocol"[: ]*"shadowsocks' $argv[1]
    return $status
end
function vconfig_run_ss
    set config $argv[1]
    set lport $argv[2]
    set -l addr (cat $config | jq -r .outbounds[0].settings.servers[0].address )
    set -l algo (cat $config | jq -r .outbounds[0].settings.servers[0].method  )
    set -l pswd (cat $config | jq -r .outbounds[0].settings.servers[0].password)
    set -l port (cat $config | jq -r .outbounds[0].settings.servers[0].port    )
    if eval $ss --tcp-fast-open 2>&1 | grep missing..local_address > /dev/null
        # rust
        eval $ss -s $addr:$port -m $algo -k $pswd -b 0.0.0.0:$lport --tcp-fast-open
    else
        # libev and python
        eval $ss -s $addr -p $port -m $algo -k $pswd -b 0.0.0.0 -l $lport --fast-open
    end
    return $status
end
function vconfig_run_v
    set config $argv[1]
    set port $argv[2]
    set tmpf "/tmp/.proxy.fish.$port.json"
    cat $config | sed "s/10808/$port/g" > $tmpf
    echo "Using config $tmpf"
    if v2ray version < /dev/null 2> /dev/null | grep 'Ray 5'
        v2ray run -c $tmpf; and rm -f $tmpf
    else
        v2ray -c $tmpf; and rm -f $tmpf
    end
    return $status
end

#### main logic start ####

set cache_file $HOME/.cache/proxy.fish-cache.txt
if test (count $argv) != 2
    echo "Naive proxy script by Recolic.
Supports: 
    shadowrocket-style subscription url:
      shadowsocks (basic parser)
      vless, vmess (basic v2ray config supported by vmess2json.py. Fancy config or xray not supported)
    ssh proxy:
      use .ssh/config
Usage: ./proxy.fish <node_name> <listen_port>
                    <node_name> must be basic-regex safe
Usage: ./proxy.fish <path/to/v2ray.json> <listen_port>
Usage: ./proxy.fish <ssh_config_host> <listen_port>
Node list from subscription cache file:"
    grep "^[^ ]* " $cache_file 2>/dev/null
    exit 1
end

set node $argv[1]
set port $argv[2]

if not test -e $cache_file || test (math (date +%s) - (stat -c %Y $cache_file)) -gt 604800
    echo "cache file not exist or older than 7 days. downloading $cache_file..."
    mkdir -p $HOME/.cache ; rm -f $cache_file
    download_subs > $cache_file
end

if test -f $node
    echo "Using $node..."
    set vconfig_path $node
else if grep "^$node " $cache_file
    echo "Using $node from subscription..."
    set vconfig_path "/tmp/.proxy.fish.$port.json"
    get_vconfig_from_subs $node $port $cache_file $vconfig_path ; or exit 1
else if grep -i "^host $node" $HOME/.ssh/config
    echo "Using ssh proxy $node..."
    while true
        ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=3 -D 0.0.0.0:$port -N -C $node
        sleep 0.5 ; or exit # Allow ctrl-C
    end
else
    echo "Invalid node name $node because ./$node doesnt exist as file, not in $cache_file, not in .ssh/config"
    exit 2
end

if vconfig_ss_available $vconfig_path
    vconfig_run_ss $vconfig_path $port
else
    vconfig_run_v $vconfig_path $port
end

exit $status
