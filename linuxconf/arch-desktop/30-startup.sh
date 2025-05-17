lc_assert_user_is root

# Warning: /usr/mybin is not in PATH!

lc_startup () {
    if [[ $(hostname) = RECOLICPC ]]; then
        # unsafe
        #mount --uuid 6bf759e4-4a2c-47f5-ab31-00e69d710b12 /harddisks/u &&
        #    swapon /harddisks/u/swapfile
        
        lc_bgrun /dev/null bash files/srv-deps/auto-nfs-mgr.sh
    fi
    
    if [[ $(hostname) = RECOLICMPC ]]; then
        swapon /dev/grp/swap
        sysctl -w vm.swappiness=75
        # Use laptop-power-save.sh as needed
    
        lc_bgrun /dev/null bash files/srv-deps/auto-nfs-mgr.sh
    fi
}
