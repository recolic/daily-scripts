#!/usr/bin/fish

function echo2
    echo $argv >> /dev/fd/2
end

# Fake functions for test
function rsync
    set -l ret (random choice 1 1 0)
    echo2 "SIMULATE # rsync $argv = $ret"
    return $ret
end
function tar
    set -l ret (random choice 0 0)
    echo2 "SIMULATE # tar $argv = $ret"
    return $ret
end
function date
    set -l ret (random 0 31)
    echo2 "SIMULATE # date $argv = $ret"
    echo $ret
    return 0
end

source daily.fish



