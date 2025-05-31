#!/bin/fish
# This script should run daily & monthly & annually, to create a zfs snapshot
# Argument: daily or monthly or annually. 
#           daily: create a snapshot every day
#           monthly: create a monthly snapshot and delete all daily snapshots
#           annually: create a annually snapshot and delete all monthly snapshots

switch $argv[1]
    case daily
        /root/nfs-backup-flist.sh
        zfs snapshot nas-data-raid@daily-(date +%Y%m%d-%H%M)
        exit $status
    case monthly
        zfs snapshot nas-data-raid@monthly-(date +%Y%m%d-%H%M)
            or exit $status # If monthly snapshot failed, do not delete daily snapshots. 
        for dailys in (zfs list -t snapshot nas-data-raid | cut -d ' ' -f 1 | grep @daily)
            echo "Deleting daily snapshot $dailys..."
            zfs destroy $dailys
        end
    case annually
        zfs snapshot nas-data-raid@annually-(date +%Y%m%d-%H%M)
            or exit $status
        for monthlys in (zfs list -t snapshot nas-data-raid | cut -d ' ' -f 1 | grep @monthly)
            echo "Deleting monthly snapshot $monthlys..."
            zfs destroy $monthlys
        end
end



