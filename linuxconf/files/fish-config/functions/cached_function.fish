
function cached_function
    # Used in fish_prompt. For huge git repo, executing `git` on every fish_prompt is slow. 
    # We can used `cached_function git ...` for faster prompt. 
    # 
    # Warning: command quotes will be evaluated before entering this func! 
    #          `cat 'hello world man.txt'` will not work! use `cat "'hello world man.txt'"`. 

    if test "$enable_cached_func" != 1
        eval $argv
        return $status
    end
   
    mkdir -p /tmp/.recolic-fish
    set cksum (echo "$argv"(pwd) | cksum | sed 's/ .*$//g')
    set cached_file "/tmp/.recolic-fish/cached_function.$cksum"

    # Warning: race condition: "[[ ! -f $cached_file.ongoing ]] && touch $cached_file.ongoing" is not atomic. 
    nohup bash -c "[[ ! -f $cached_file.ongoing ]] && touch $cached_file.ongoing && $argv > $cached_file.ongoing && mv $cached_file.ongoing $cached_file" > /dev/null 2>&1 & disown

    while not test -f $cached_file
        sleep 0.1
    end

    cat $cached_file
end

