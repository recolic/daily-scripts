#!/bin/fish
# delete all resource group with keyword "recolic-" unless whitelisted
for grp in (az group list --subscription Datapath\ Test\ Subscription | json2table /name | grep 'rshgrp-[^ ]*' -o)
    string match '*recolic-test-bensl*' $grp ; and continue
    echo "DEL $grp"
    az group delete --resource-group $grp --yes --subscription Datapath\ Test\ Subscription --force-deletion-types Microsoft.Compute/virtualMachines
end 

