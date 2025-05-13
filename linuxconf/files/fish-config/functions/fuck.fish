# Defined in - @ line 2
function fuck
    # patch: auto-detech if git branch has no upstream on push
    if string match 'git push' $history[1]
        if git branch -vv | grep '^\\*' | grep -vF '[' > /dev/null
            # git branch lack upstream
            eval $history[1] --set-upstream (git remote | head -n 1) (git branch --show-current)
            return $status
        end
    end

    # default: sudo
	eval sudo $history[1]
    and echo 'qaq...'
end
