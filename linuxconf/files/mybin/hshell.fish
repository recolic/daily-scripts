#!/bin/fish

gpg -d (dirname (status --current-filename))/lib/hshell.env.gpg > /tmp/.hs.fish ; or exit 1
gpgconf --reload gpg-agent # Next PIN would be required.
env RECOLIC_ENV_NAME=HSHELL fish --private -C 'source /tmp/.hs.fish'

