#!/bin/bash
_dom="$1"
_slient=1

[[ "$_dom" = "" ]] && echo 'Incomplete argument.' && exit 19
[[ "$_dom" = "s" ]] && _slient=1 && _dom="$2" && shift

shift

cd ~/?ext?loud/notebooks/.secrets || exit 1

chmod +x pswdGen
if [[ $_slient = 0 ]]; then
    SEED=$(gpg -d .seed.encrypt | base64) &&
    printf '%s' "$SEED" | base64 --decode | ./pswdGen -s - -f $_dom -y $* -l 16
else
    SEED=$(gpg -d .seed.encrypt | base64) &&
    printf '%s' "$SEED" | base64 --decode | ./pswdGen -s - -f $_dom -y $* -l 16 | sed 's/^.* //g' | tr -d '\n'
fi
cd - > /dev/null

