#!/bin/bash

set -e

# git restore config/vim/.netrwhist
git stash clear || true

git fetch
git stash
git pull
git stash apply || true # This command would fail if no stashed change

git add -A
git commit -m ".$1" || true # fail if no change
git push

# copy to mirror
msmirror=$HOME/code/msdoc/proj/sh-mirror
if [[ -d $msmirror ]]; then
    rm -rf $msmirror/*/ # remove all directories
    cp -r linuxconf/files/mybin linuxconf/files/mymsbin $msmirror/

    rm -f $msmirror/mymsbin/oespolicy
    gpg -d -o $msmirror/mymsbin/oespolicy $msmirror/mymsbin/oespolicy.gpg
fi

