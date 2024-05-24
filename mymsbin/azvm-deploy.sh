#!/bin/bash
# This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.

location="$1"
vmcount="$2"
tipid="$3"
cluster="$4"

vmsize="${vmsize:=Standard_D2_v5}"
vnet_enc="${vnet_enc:1}"
vnet_dual_stack="${vnet_dual_stack:1}"
accelnet=1

prefix="${prefix:=$(head -c8 /dev/urandom | base64 -w0 | tr -d =/)}"
resgrp="${resgrp:=rsh-$prefix-resgrp}"
avname="${avname:=$prefix-av}"
vnetname="${vnetname:=$prefix-vnet}"
vmname="${vmname:=$prefix-vm}"

## Check usage... Script user: Do not modify below this line.
[ "$vmcount" = "" ] && echo "This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.
Usage: $0 <location> <vmcount> [tipid] [cluster]
Example: $0 eastus2euap 2
         $0 eastus2euap 2 69b25fda-d568-4460-b515-0c77ef6719ce CBN09PrdApp09
Optionally, you can override other variables by setting corresponding env.
" && exit 1

vm_create_xtra_arg=()
vnet_create_xtra_arg=()

[ "$vnet_enc"        = 1 ] && vnet_create_xtra_arg+=(--enable-encryption true --encryption-enforcement-policy allowUnencrypted)
[ "$vnet_dual_stack" = 1 ] && addr_prefixes=('10.0.0.0/16' 'fd00:db8:deca::/48') || addr_prefixes=('10.0.0.0/16')
[ "$accelnet"        = 1 ] && vm_create_xtra_arg+=(--accelerated-networking true)
[ "$R_SEC_WEAK12"    = "" ] && R_SEC_WEAK12=dummypassW12

## all args ready to go!


echo "Deploying $vmcount $vmsize VMs at location $location, using res_grp $resgrp, vmname $vmname ..."
az group create -n "$resgrp" --location "$location" > /dev/null 2>&1

# Create an availability set if we want deploy into TiP.
if [ "$tipid" != "" ]; then
    echo "Using TiP session $tipid at cluster $cluster"

    # `az vm availability-set create` doesn't allow setting internalData.pinnedFabricCluster, we must use the ugly ARM deployment.
    echo "H4sIAAAAAAAAA31TTY/aMBC98ysst9K2EoTAtofurWK1Ug/bC7u9rFA1JAOZ1rEtewKiiP9eOwmw4SuJFGvem5k3H972RHjkR58VWIJ8ELJgtv5hOGwsSQkallii5gT+VQ6TzJQt5ofjdPRtkH4ZpKNhjlaZTeS9YGkVMCZ/vNEfZL/JkBnNAfyFzpPRMdEoSeO7J1hwUCIHPIDb2lbbYaWDPdiE2Ere2HiUU3akl3LXP/KUyYCb0Dd5TJbyOtxtXqYqH9RE5jmvprVsuQJHMFd4Ivx36FTsR/SLDVkYV77aPHTm0ZRAemIqzQJ0LvboE1SKO6BDkeMimgUbMRKkxZp0btZe+MyR5URow8KHwYh1AewFFyhKBB1kJuLVh5+o57aPIzvSHXpTuayW/naQfiyi6Vhb/DNlzniz4GRiSlsxDmEFpGBOingzRfay3/UES+8GPk7H94M0fKNTXjth+XZcgk93zeDvPs9O2e8m3fXYAxd8GJbd8RyQF7I/TY7JFH0U+iM/C1tvTIzZcd6dZPB/q8sJ9sV9V7TUmN+OYp2x6JjwitqrixToX/vX+aerFejjC3QKl9RpUI/AcFFAE5R0KOQJ5o6yyeGadJvWXp+ztl0ouo65IscVqGfICtLNPs66nep1T7Pervcf6ISSqr4EAAA=" | gzip -d | base64 -d > /tmp/template-avset.json
    echo "EXEC #" az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster"
    az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster" || exit $?
    vm_create_xtra_arg+=(--availability-set "$avname")
fi

# Create vnet with optional dual_stack and encryption support
echo "Deploying vnet ${vnetname} at location $location, using res_grp $resgrp, vnet_enc $vnet_enc, vnet_dual_stack $vnet_dual_stack ..."
az network vnet create \
    --resource-group "${resgrp}" \
    --location "${location}" \
    --name "${vnetname}" \
    --subnet-name default \
    --address-prefixes "${addr_prefixes[@]}" \
    ${vnet_create_xtra_arg[@]}

for cter in $(seq $vmcount); do
    echo "EXEC #" az vm create --name "$vmname-$cter" -g "$resgrp" --image Ubuntu2204 --admin-password $R_SEC_WEAK12 --admin-username r --location "$location" --size "$vmsize" --vnet-name "$vnetname" --subnet default "${vm_create_xtra_arg[@]}"
    az vm create --name "$vmname-$cter" -g "$resgrp" --image Ubuntu2204 --admin-password $R_SEC_WEAK12 --admin-username r --location "$location" --size "$vmsize" --vnet-name "$vnetname" --subnet default "${vm_create_xtra_arg[@]}" || exit $?
done

