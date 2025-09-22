function _is_gpg_vault
    set fname $argv[1]
    if file $fname | grep "PGP message Public-Key Encrypted" > /dev/null
        return 0 # Yes
    end 
    if file $fname | grep 'data$' > /dev/null
        if string match -q '*.gpg' -- $fname
            return 0 # Yes
        end
    end 
    return 1 # No
end
function svim
    set _origin_vim /usr/bin/vim
    if test -z "$argv"
        $_origin_vim
        return $status
    end 

    set fname $argv[1]
    if not test -e $fname
        if _svim_try_touch_file $fname
            $_origin_vim $argv
            return $status
        else
            sudo $_origin_vim $argv
            return $status
        end
    end 
    if test -w $fname ; and test -r $fname
        if type -q rgpg-vim ; and _is_gpg_vault $fname
            rgpg-vim $fname
        else
            $_origin_vim $argv
        end
    else
        sudo $_origin_vim $argv
    end 
    return $status
end

