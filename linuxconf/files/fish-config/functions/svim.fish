# Defined in - @ line 2
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
        if type -q rgpg-vim ; and file $fname | grep "PGP message Public-Key Encrypted" > /dev/null
            rgpg-vim $fname
        else
            $_origin_vim $argv
        end
    else
        sudo $_origin_vim $argv
    end
    return $status
end
