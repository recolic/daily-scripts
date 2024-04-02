#!/usr/bin/fish

# recolic note: how to deploy
# bgrun /var/log/autoprint-daemon.log /root/autoprint-daemon.fish

while true
    for fl in /root/nfs/autoprint/*.pdf
        echo Printing $fl at (date) ...
        lp $fl
        rm $fl
    end
    sleep 60
end


