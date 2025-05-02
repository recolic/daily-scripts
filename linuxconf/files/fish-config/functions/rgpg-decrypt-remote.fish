function rgpg-decrypt-remote
    if [ (count $argv) != 2 ]
        echo 'Usage: rgpg-decrypt-remote user@remote.example.com path/encrypted.gpg'
        return 1
    end
    
    set host $argv[1]
    set f $argv[2]
    set ret 0

    # strip .gpg/.asc if any, replace inplace if none.
    set remote_plain (echo $f | sed -E 's/\\.(gpg|asc)$//')
    set local_tmp "/tmp/.rgpg-tmp."(echo $f | sha256sum | head -c 20)
    
    scp "$host:$f" "$local_tmp"
    and gpg --decrypt -o "$local_tmp.plain" "$local_tmp"
    and scp "$local_tmp.plain" "$host:$remote_plain"
    or set ret $status
    
    rm -f "$local_tmp.plain" "$local_tmp" > /dev/null 2>&1
    return $ret
end
