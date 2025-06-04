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

