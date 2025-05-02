lc_assert_user_is root

# Warning: /usr/mybin is not in PATH!

DEPS_PREFIX="files/srv-deps"

function mount_nfs () {
    while true; do
        ping -c 1 hms.r && break
        sleep 2
    done
    mount -o bg,intr,soft,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
}

function barrier_wait_for_internet () {
  while true; do
    ping -c 1 cloudflare.com && break
    sleep 2
  done
}

lc_startup () {
    if [[ $(hostname) = RECOLICPC ]]; then
        # unsafe
        #mount --uuid 6bf759e4-4a2c-47f5-ab31-00e69d710b12 /harddisks/u &&
        #    swapon /harddisks/u/swapfile
        
        lc_bgrun /dev/null bash $DEPS_PREFIX/auto-nfs-mgr.sh
    fi
    
    if [[ $(hostname) = RECOLICMPC ]]; then
        swapon /dev/grp/swap
        sysctl -w vm.swappiness=75
        # Use laptop-power-save.sh as needed
    
        lc_bgrun /dev/null bash $DEPS_PREFIX/auto-nfs-mgr.sh
    fi
       
    barrier_wait_for_internet
    
    curl 'https://recolic.net/api/cloudlog.php' --data "lc.arch-desktop Powered up $(uname -a)"
}
