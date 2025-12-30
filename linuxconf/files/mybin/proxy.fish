#!/usr/bin/fish
# v1.06.202511

set script_dir (dirname (status --current-filename))
function download_subs
    if not set -q SUB_URLS
        echo "Note: set env 'SUB_URLS' to use shadowrocket subscription. Example:" 1>&2
        echo "export SUB_URLS='https://example.com/sub/api?key=12345 https://backup.com/dumb?user=trump' # bash" 1>&2
        echo "set -gx SUB_URLS 'https://example.com/sub/api?key=12345' 'https://backup.com/dumb?user=trump' # fish" 1>&2
        set p (rsec ProxySub_API)
        set SUB_URLS "$p?2" "$p?3a"
    end
    
    for URL in $SUB_URLS
        echo "DOWNLOAD SUBS : $URL" 1>&2
        curl -s "$URL" | base64 -d | dos2unix | while read -l line
            echo "$line" | grep "://" > /dev/null 2>&1 ; or continue
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
    # sed doesnt work with unicode
    set url (grep "^$node " $in_cachefile | sed "s|^[^ ]* ||") ; or return 1
    echo "$url" | python $script_dir/lib/vmess2json.py --inbounds "socks:$port" -o "$out_vconfigfile" ; or return 1
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
    echo "Using config $config..."
    if v2ray version </dev/null 2>/dev/null | grep 'Ray 5' >/dev/null
        v2ray run -c $config; and rm -f $config
    else
        v2ray -c $config; and rm -f $config
    end
    return $status
end

function help1
    echo """Naive proxy script by Recolic.
Supports: 
    shadowrocket-style subscription url:
      shadowsocks (basic parser)
      vless, vmess (basic v2ray config supported by vmess2json.py. Fancy config or xray not supported)
    ssh proxy:
      use .ssh/config
Usage:
    ./proxy.fish <node_name> <listen_port>
    ./proxy.fish <path/to/v2ray.json> <listen_port>
    ./proxy.fish <ssh_config_host> <listen_port>
                 <node_name> must be basic-regex safe
Completion file available at linuxconf/files/fish-config/completions/proxy.fish.fish"""
end

#### main logic start ####

set cache_file $HOME/.cache/proxy.fish-cache.txt
function help2
    echo "Node list from subscription cache file:"
    grep -o "^[^ ]* " $cache_file 2>/dev/null
    if test -f $cache_file
        echo "To flush cache, delete the cache_file $cache_file and run 'proxy.fish dummy 1'"
    else
        echo "*** before first run: please modify this script, update SUB_URLS, and run 'proxy.fish dummy 1'"
    end
end
if test (count $argv) != 2
    help1 ; help2
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
else if grep -i "^$node " $cache_file > /dev/null 2>&1
    echo "Using $node from subscription..."
    set vconfig_path "/tmp/.proxy.fish.$port.json"
    get_vconfig_from_subs $node $port $cache_file $vconfig_path ; or exit 1
else if grep -i "^host $node" $HOME/.ssh/config > /dev/null 2>&1
    echo "Using ssh proxy $node..."
    while true
        ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=3 -D 0.0.0.0:$port -N -C $node
        sleep 0.5 ; or exit # Allow ctrl-C
    end
else
    echo "Invalid node name $node because ./$node doesnt exist as file, not in $cache_file, not in .ssh/config"
    help2
    exit 2
end

if vconfig_ss_available $vconfig_path
    vconfig_run_ss $vconfig_path $port
else
    vconfig_run_v $vconfig_path
end

exit $status
