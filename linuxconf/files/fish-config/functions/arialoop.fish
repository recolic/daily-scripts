function arialoop
    while true
        aria2c -x5 $argv
        and break
        sleep 1
    end
end
