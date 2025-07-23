function rnfs
    set nfsu (mount | grep "$HOME/nfs " >/dev/null; or echo 1)
    
    test "$nfsu" = "1"; and echo "++ mount nfs..." ; and rnfs.mount
    env "RECOLIC_ENV_NAME=with_nfs" fish -C "cd $HOME/nfs"
    test "$nfsu" = "1"; and echo "-- umount nfs..." ; and sudo umount -f -l $HOME/nfs
end
