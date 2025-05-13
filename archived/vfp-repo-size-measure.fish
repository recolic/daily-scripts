rm -rf repo
rm -f /tmp/outputsize

cp -r repo.backup repo
# git clone xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/vvv.git repo
cd repo

## create a local branch for every remote branch, so `git log --reflog` will list all of them.
for branch in (git branch -a | grep '^\s*remotes' | tr -d ' ')
    git branch --track "$(echo $branch | base64 -w0)" "$branch"
end

## every commit must have at least one tag, so they could be removed one by one.
## otherwise, if you have commits: 1--------3 (branch1)
##                                      2 (branch2)
## after removing 3, 1 will be removed with 3.
git log --reflog --decorate --date 'raw' | grep -E '^commit ' > /tmp/commits
set num 1
for line in (grep commit /tmp/commits)
    set commitid (echo "$line" | grep -Eo '[0-9a-f]{40}')
    if string match '*(*' $line
        continue
    else
        git tag bensl/reservedseq/$num $commitid
        set num (math 1+$num)
    end
end

## Done. pull commits file again
git log --reflog --decorate --date 'raw' | grep -E '^(commit |Date:)' > /tmp/commits
git gc --prune=now

for line in (grep commit /tmp/commits)
    set commitid (echo "$line" | grep -Eo '[0-9a-f]{40}')
    echo REMOVE ALL TAG $commitid

    git checkout $commitid

    if string match '*(*' $line
        # has tag
        set tags_ar (echo "$line" | sed 's/tag: //g' | sed 's/^.*(//' | sed 's/)$//' | sed 's/^.*-> //' | tr -d ' ' | string split ,)
        for tag in $tags_ar
            git branch -D $tag
            or git branch -D $tag --remote
            or git tag -d $tag
            or begin
                echo "FAILED DELETE $tag"
                exit 1
            end
        end
    end

    git checkout -b bensl/reserved/tmp # protect this commit
    and git reflog expire --expire-unreachable=now --all
    and git gc --prune=now
    and git checkout $commitid
    and git branch -D bensl/reserved/tmp
    or exit 1

    set size (du -hd0 .git | cut -f 1)
    set timestamp (git show --no-patch --format=%ct $commitid)
    echo "$commitid:$timestamp:$size" | tee -a /tmp/outputsize
end



