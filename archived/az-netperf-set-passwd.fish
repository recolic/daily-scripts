#!/bin/fish
# az-netperf-set-passwd.fish version 1.04

azswitch ms

set keyword $argv[1]
if test "$keyword" = ""
    echo missing keyword
    exit 1
end
echo "Searching subscription with keyword $keyword"
set vmids (az vm list --subscription 014e7430-fd92-4579-9119-e861d926508a | json2table /id -p | grep $keyword | sed 's/VAL: //g' | tr -d '|')
or begin
    echo NEED az login
end

if test "$R_SEC_WEAK12" = ""
    set R_SEC_WEAK12 dummypassW12
end

for vm in $vmids
    echo "Set password: $vm"
end

for vm in $vmids
    az vm user update --ids $vm --username r --password "$R_SEC_WEAK12"
end

echo "Your VM INFO ===================="
echo "sshpass -p $R_SEC_WEAK12 ssh r@"
for vm in $vmids
    az vm list-ip-addresses --ids $vm | json2table /virtualMachine/network/publicIpAddresses/name,ipAddress
end

