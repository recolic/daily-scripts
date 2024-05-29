#!/bin/bash
# This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.

location="$1"
vmcount="$2"
tipid="$3"
cluster="$4"

vmsize="${vmsize:=Standard_D2_v5}"
vnet_enc=0 # not working yet
vnet_dual_stack=0 # not working yet
accelnet=1
# At 202405, the following image are allowed for internal use: ["2022-datacenter-azure-edition","2022-datacenter","2022-datacenter-core","2022-datacenter-azure-edition-core","2022-datacenter-core-g2","2022-datacenter-g2","pro-22_04","pro-22_04-gen2","24_04","24_04-gen2","22_04-lts-arm64","azure-linux-3","azure-linux-arm64","azure-linux-gen2","1-gen2","cbl-mariner-1","cbl-mariner-2","cbl-mariner-2-arm64","cbl-mariner-2-fips","cbl-mariner-2-gen2","cbl-mariner-2-gen2-fips","cbl-mariner-2-kata","79-gen2"]
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
# az vm image list --publisher  Canonical --output table --all | grep 0001-com-ubuntu-pro-microsoft | grep 22_04-gen2
vmimg=Canonical:0001-com-ubuntu-pro-microsoft:pro-22_04-gen2:22.04.202405240

prefix="${prefix:=$(head -c8 /dev/urandom | base64 -w0 | tr -d =/+)}"
resgrp="${resgrp:=rshgrp-$prefix}"
avname="${avname:=$prefix-av}"
vnetname="${vnetname:=$prefix-vnet}"
vmname="${vmname:=$prefix-vm}"

## Check usage... Script user: Do not modify below this line.
[ "$vmcount" = "" ] && echo "This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.
Usage: $0 <location> <vmcount> [tipid] [cluster]
Example: $0 eastus2euap 2
         $0 eastus2euap 2 69b25fda-d568-4460-b515-0c77ef6719ce CBN09PrdApp09

Optionally, you can override other variables by setting corresponding env. For example:
         resgrp=mygrp vmsize=Standard_D2_v3 $0 eastus2euap 2 ...
" && exit 1

vm_create_xtra_arg=()
vnet_create_xtra_arg=()

[ "$vnet_enc"        = 1 ] && vnet_create_xtra_arg+=(--enable-encryption true --encryption-enforcement-policy allowUnencrypted)
[ "$vnet_dual_stack" = 1 ] && vnet_create_xtra_arg+=(--address-prefixes '10.0.0.0/16' 'fd00:db8:deca::/48')
[ "$accelnet"        = 1 ] && vm_create_xtra_arg+=(--accelerated-networking true)
[ "$R_SEC_WEAK12"    = "" ] && R_SEC_WEAK12=dummypassW12

## all args ready to go!


echo "Deploying $vmcount $vmsize VMs at location $location, using res_grp $resgrp, vmname $vmname ..."
az group create -n "$resgrp" --location "$location" > /dev/null 2>&1

# Create an availability set if we want deploy into TiP.
if [ "$tipid" != "" ]; then
    echo "Using TiP session $tipid at cluster $cluster"

    # `az vm availability-set create` doesn't allow setting internalData.pinnedFabricCluster, we must use the ugly ARM deployment.
    echo "H4sIAAAAAAAAA31TTY/aMBC98ysst9K2EoTAtofurWK1Ug/bC7u9rFA1JAOZ1rEtewKiiP9eOwmw4SuJFGvem5k3H972RHjkR58VWIJ8ELJgtv5hOGwsSQkallii5gT+VQ6TzJQt5ofjdPRtkH4ZpKNhjlaZTeS9YGkVMCZ/vNEfZL/JkBnNAfyFzpPRMdEoSeO7J1hwUCIHPIDb2lbbYaWDPdiE2Ere2HiUU3akl3LXP/KUyYCb0Dd5TJbyOtxtXqYqH9RE5jmvprVsuQJHMFd4Ivx36FTsR/SLDVkYV77aPHTm0ZRAemIqzQJ0LvboE1SKO6BDkeMimgUbMRKkxZp0btZe+MyR5URow8KHwYh1AewFFyhKBB1kJuLVh5+o57aPIzvSHXpTuayW/naQfiyi6Vhb/DNlzniz4GRiSlsxDmEFpGBOingzRfay3/UES+8GPk7H94M0fKNTXjth+XZcgk93zeDvPs9O2e8m3fXYAxd8GJbd8RyQF7I/TY7JFH0U+iM/C1tvTIzZcd6dZPB/q8sJ9sV9V7TUmN+OYp2x6JjwitqrixToX/vX+aerFejjC3QKl9RpUI/AcFFAE5R0KOQJ5o6yyeGadJvWXp+ztl0ouo65IscVqGfICtLNPs66nep1T7Pervcf6ISSqr4EAAA=" | base64 -d | gzip -d > /tmp/template-avset.json
    echo "EXEC #" az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster"
    az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster" || exit $?
    vm_create_xtra_arg+=(--availability-set "$avname")
fi

# Manually create vnet if we need dual_stack or vnet_enc
if [ "$vnet_enc" = 1 ] || [ "$vnet_dual_stack" = 1 ]; then
    echo "Deploying vnet ${vnetname} at location $location, using res_grp $resgrp, vnet_enc $vnet_enc, vnet_dual_stack $vnet_dual_stack ..."
    echo "EXEC #" az network vnet create --resource-group "${resgrp}" --location "${location}" --name "${vnetname}" --subnet-name default "${vnet_create_xtra_arg[@]}"
    az network vnet create --resource-group "${resgrp}" --location "${location}" --name "${vnetname}" --subnet-name default "${vnet_create_xtra_arg[@]}" || exit $?
fi

for cter in $(seq $vmcount); do
    echo "EXEC #" az vm create --name "$vmname-$cter" -g "$resgrp" --image "$vmimg" --admin-password $R_SEC_WEAK12 --admin-username r --location "$location" --size "$vmsize" --vnet-name "$vnetname" --subnet default "${vm_create_xtra_arg[@]}"
#Ubuntu2204 
    az vm create --name "$vmname-$cter" -g "$resgrp" --image "$vmimg" --admin-password $R_SEC_WEAK12 --admin-username r --location "$location" --size "$vmsize" --vnet-name "$vnetname" --subnet default "${vm_create_xtra_arg[@]}" || exit $?
done

