#!/usr/bin/fish
# v1.04.202508
# naive proxy script supporting:
#   shadowrocket-style subscription url:
#     shadowsocks (basic parser)
#     vless, vmess (basic v2ray config supported by vmess2json.py. Fancy config or xray not supported)
#   ssh proxy:
#     use .ssh/config

function list_possible_nodename
    set nextcloud_root $HOME/(ls $HOME | grep -i nextcloud | head -n1)
    set possible_path $nextcloud_root/documents/proxy/comm100-nodes/
    # echo ss
    ls $possible_path/*.json | sed 's|^.*/||g' | sed 's/.json//g'
end

if test (count $argv) != 2
    echo "Usage: ./proxy.fish <node_name> <listen_port>"
    echo "Usage: ./proxy.fish <path/to/template.json> <listen_port>"
    echo "Possible node name:"
    list_possible_nodename
    exit 1
end

type ss-local ; and set ss ss-local ; or set ss sslocal

function vconfig_is_ss
    test "$ss" != "" ; and grep 'protocol"[: ]*"shadowsocks' $argv[1]
    return $status
end
function vconfig_run_ss
    set config $argv[1]
    set lport $argv[2]
    set -l config_line (cat $config | json2table /outbounds/settings/servers -p)
    # addr.example.com|NAME@ss|chacha20-ietf-poly1305|0|password|25551|
    set -l addr (echo $config_line | string split '|')[1]
    set -l algo (echo $config_line | string split '|')[3]
    set -l pswd (echo $config_line | string split '|')[5]
    set -l port (echo $config_line | string split '|')[6]
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

set node $argv[1]
set port $argv[2]

set nextcloud_root $HOME/(ls $HOME | grep -i nextcloud | head -n1)
set possible_path $nextcloud_root/documents/proxy/comm100-nodes/$node.json
if test -f $node
    echo "Using $node..."
    set possible_path $node
else if test -f $possible_path
    echo "Using $possible_path..."
else if string match -q "*.recolic" -- "$node"
    echo "Using ssh proxy $node..."
    while true
        ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=3 -D 0.0.0.0:$port -N -C $node
        sleep 0.5 ; or exit # Allow ctrl-C
    end
else
    echo "Invalid node name $node because ./$node and $possible_path does not exist"
    exit 2
end

if vconfig_is_ss $possible_path
    vconfig_run_ss $possible_path $port
else
    vconfig_run_v $possible_path $port
end

exit $status
