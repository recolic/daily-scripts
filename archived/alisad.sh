#!/bin/bash
# Mar 14, 2018, by Recolic Keghart <root@recolic.net>
# Sync Alisahhh.github.io to ./alisa (->./old_repo_alisa)
# Serving as: https://alisa.asia/
# Dependency: alisa_fix.sh

function git_uptodate () {
    git status | grep fatal && exit 1
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")
    
    if [ $LOCAL = $REMOTE ]; then
        echo "Up-to-date"
        return 0
    elif [ $LOCAL = $BASE ]; then
        echo "Need to pull"
        return 1
    elif [ $REMOTE = $BASE ]; then
        echo "Need to push"
        return 0
    else
        echo "Diverged"
        return 126
    fi
}

function do_update_help () {
    git clone https://github.com/Alisahhh/Alisahhh.github.io.git new_repo_alisa && ./alisa_fix.sh new_repo_alisa &&
    rm -f alisa && ln -s new_repo_alisa alisa &&
    rm -rf old_repo_alisa &&
    mv new_repo_alisa old_repo_alisa && rm alisa && ln -s old_repo_alisa alisa
}

function do_update () {
    if cd alisa 2>/dev/null
    then
        git_uptodate || do_update_help
        cd -
    else
        do_update_help
    fi
}

function _sleep () {
    echo "Sleeping $1 s..."
    sleep $1
}

[[ $1 == '--force' ]] && do_update_help && _sleep 600

while true; do
    do_update
    _sleep 600
done

