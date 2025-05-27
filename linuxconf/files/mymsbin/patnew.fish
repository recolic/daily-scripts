#!/bin/fish
## This script prints cached PAT token if expired, create a new one otherwise.
# starting 04/15, stupid az devops only allows 7-day PAT, not 90 days.
# It's stupid to keep clicking clicking clicking every day. This script request PAT automatically.


set NEXTCLOUD_PREFIX $HOME/(ls $HOME | grep -i '^nextcloud$' | head -n1)
set token_cache_file $NEXTCLOUD_PREFIX/tmp/pat-token.txt # TODO: find a good loc

set make_web_req_func "
-----BEGIN PGP MESSAGE-----

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
sMYJ5LwEuGKgzWQu
=QqGG
-----END PGP MESSAGE-----"

# use this sample function for testing. 
function make_web_req_sample
    echo "VAL: g5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx3a|"
end

function GenNewToken
    echo "Decrypt make_web_req_func & Generating new token..." 1>&2
    echo "$make_web_req_func" | gpg -d | source
        or return 1
    set -l token (make_web_req | cut -d ' ' -f 2 | tr -d '|')
        or return 1
    test "$token" != ""
        or return 1
################################### Starting ChatGPT generated code ##############################
    set -l creation_time (date +%s)
    set -l expire_time (math "7 * 24 * 60 * 60 + $creation_time") # after 7 days
    echo "$token $expire_time" > $token_cache_file
end

# Function to check if token is still valid and print it if valid
function is_cache_valid
    if not test -f $token_cache_file
        return 1
    end

    set -l token_expire_time (cut -d ' ' -f 2 $token_cache_file)
    set -l current_time (date +%s)

    if test $current_time -lt $token_expire_time
        return 0  # Token is valid
    else
        return 1  # Token expired
    end
end

function print_token_cache
    set -l token (cut -d ' ' -f 1 $token_cache_file)
    echo $token
end

# Main script logic
if not is_cache_valid
    if test "$DONT_REGEN_EXPIRED_TOKEN" = 1
        echo "> Warning: Microsoft PAT outdated! Run patnew.fish to re-generate it." 1>&2
        return 1
    end
    GenNewToken
    or return $status
end

print_token_cache

