#!/usr/bin/fish
# v1.03.202403

function list_possible_nodename
    set nextcloud_root $HOME/?ext?loud
    set possible_path $nextcloud_root/workspace/impl/proxy/comm100-nodes/
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

type ss-local
    and set ss ss-local
    or set ss sslocal

set node $argv[1]
set port $argv[2]

set mypath (dirname (status --current-filename))
function runv
    set config $argv[1]
    set port $argv[2]
    set tmpf (mktemp).json
    cat $config | sed "s/10808/$port/g" > $tmpf
    echo "Using config $tmpf"
    if v2ray version < /dev/null 2> /dev/null | grep 'Ray 5'
        v2ray run -c $tmpf; and rm -f $tmpf
    else
        v2ray -c $tmpf; and rm -f $tmpf
    end
    return $status
end

switch $node
    # case ss
    #     eval $ss -s xxxxxxx -p 11111 -k xxxxxxxxx -m chacha20-ietf-poly1305 -l $port --fast-open
    case '*'
        set nextcloud_root $HOME/?ext?loud
        set possible_path $nextcloud_root/workspace/impl/proxy/comm100-nodes/$node.json
        if test -f $node
            echo "Using $node..."
            runv $node $port
        else if test -f $possible_path
            echo "Using $possible_path..."
            runv $possible_path $port
        else
            echo "Invalid node name $node because ./$node and $possible_path does not exist"
            exit 2
        end
end
        
exit $status


