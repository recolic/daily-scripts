#!/bin/bash

# git restore config/vim/.netrwhist
git stash clear

git fetch && 
git stash &&
git pull || exit $?
git stash apply # This command would fail if no stashed change

git add -A &&
git commit -m quick_push &&
git push

exit $?

