# Defined in - @ line 2
function svim
    set _origin_vim /usr/bin/vim
    if test -z "$argv"
        $_origin_vim
        return $status
    end

    set perm_detect $argv[1]
    if not test -e $perm_detect
        if _svim_try_touch_file $perm_detect
            $_origin_vim $argv
            return $status
        else
            sudo $_origin_vim $argv
            return $status
        end
    end
    if begin test -w $perm_detect
            and test -r $perm_detect
        end
        $_origin_vim $argv
    else
        sudo $_origin_vim $argv
    end
    return $status
end
