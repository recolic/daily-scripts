if test "$R_SEC_WEAK12" = ""
    set R_SEC_WEAK12 dummypassW12
end

function give_me_a_linux
    set vmname r-wash(random 0 99999)
    az vm create -n $vmname -g recolic-wash --image Ubuntu2204 --admin-password $R_SEC_WEAK12 --admin-username recolic --location westus2 --size Standard_B1s --user-data ~/sh/wash-azdeploy/cloudinit.sh | tee /tmp/.gml
    and set ip (cat /tmp/.gml | grep publicIpAddress | sed 's/^.*: "//g' | sed 's/".*$//g')
    # and set whitelist (curl ip.sb -s4 | sed 's/[0-9]*\.[0-9]*$/0.0/g')/16
    and set whitelist 0.0.0.0/0
    and az network nsg rule create --nsg-name "$vmname"NSG --resource-group recolic-wash --name (random 1 9999999) --priority 106 --source-address-prefixes $whitelist --destination-port-ranges '*' --access Allow
    and echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    and echo "sshpass -p $R_SEC_WEAK12 ssh recolic@$ip"
    and echo "ACCESS: http://$ip:8000"
    return $status
end

azswitch recolic

az group delete --resource-group recolic-wash -y -f Microsoft.Compute/virtualMachines
az group create --resource-group recolic-wash --location westus2

give_me_a_linux

echo "CLEANUP: az group delete --resource-group recolic-wash -y -f Microsoft.Compute/virtualMachines"

