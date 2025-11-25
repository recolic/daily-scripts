#!/usr/bin/env fish

function __proxy_nodes
    set cache_file $HOME/.cache/proxy.fish-cache.txt
    grep -o "^[^ ]* " $cache_file 2>/dev/null | tr -d " "
end

complete -c proxy.fish -n "test (count (commandline -opc)) -eq 1" -k -a "(__fish_complete_user_at_hosts)" -d "SSH"
complete -c proxy.fish -n "test (count (commandline -opc)) -eq 1" -k -f -a "(find . -maxdepth 1 -name '*.json')" -d "v2ray"
complete -c proxy.fish -n "test (count (commandline -opc)) -eq 1" -k -f -a "(__proxy_nodes)" -d "v2ray"

complete -c proxy.fish -n "test (count (commandline -opc)) -eq 2" -f -a "1080 10802 10808 10809 10829" -d "Port Number"

