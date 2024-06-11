
function fuck1
    set rg $argv[1]
    set vm $argv[2]

    # set vmstat (az vm get-instance-view -g $rg -n $vm --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" --output table)
    # echo $vmstat $vm

    az vm restart -g $rg -n $vm &
    # if echo $vmstat | grep deallocated
    #     az vm start -g $rg -n $vm &
    # else if echo $vmstat | grep stopped
    #     az vm start -g $rg -n $vm &
    # else

    # end
end

for i in (seq 0 32)
    # set vm vm-bc77d28a-7dc2-47d6-99c8-8eeeeb604a62-$i
    # az vm restart -g recolic-9a53512b-0d80-43f5-ad96-7826698d96a7 -n $vm &
    fuck1 recolic-98b9514d-682d-48a3-b6f8-2feeaf33d393 vm-4a6c8554-e8fb-40f6-b8c7-f0200068fcdc-$i
    #fuck1 recolic-79c4cc7c-a8f0-4bf8-9add-6ab657c2fddb vm-9c5a2630-ad36-49a3-9b72-dbba3e1d0540-$i
end

while true
    echo ----------
    jobs
    sleep 30
    break
end

