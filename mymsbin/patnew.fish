#!/bin/fish
## This script prints cached PAT token if expired, create a new one otherwise.
# starting 04/15, stupid az devops only allows 7-day PAT, not 90 days.
# It's stupid to keep clicking clicking clicking every day. This script request PAT automatically.


set NEXTCLOUD_PREFIX $HOME/(ls $HOME | grep -i '^nextcloud$' | head -n1)
set token_cache_file $NEXTCLOUD_PREFIX/workspace/impl/pat-token.txt

function make_web_req
  hack-browser-data-linux-amd64 --dir /tmp/edgecookie -b edge 1>&2
  and set cookie_str (cat /tmp/edgecookie/microsoft_edge_*_cookie.csv | grep msazure.visualstudio.com | cut -d , -f 3,4 | tr , = | string join '; ')
  and set tokenname rauto(random)(random)
  and set validto (date --iso-8601=seconds --utc --date '6 day 12 hour' | sed 's/+00:00/Z/')
  or return 1

  set scope "vso.work_full vso.code_full vso.code_status vso.build_execute vso.release_manage vso.test_write vso.packaging_manage vso.buildcache_write vso.machinegroup_manage vso.drop_manage vso.entitlements vso.environment_manage vso.extension.data_write vso.extension_manage vso.graph_manage vso.project_manage vso.pipelineresources_manage vso.identity_manage vso.gallery_acquire vso.memberentitlementmanagement_write vso.notification_manage vso.threads_full vso.securefiles_manage vso.security_manage vso.serviceendpoint_manage vso.symbols_manage vso.taskgroups_manage vso.dashboards_manage"

  echo "Note: if you are getting json2table json parse error, please access https://msazure.visualstudio.com/ again." 1>&2
  curl 'https://msazure.visualstudio.com/_apis/Contribution/HierarchyQuery' -s \
    -H 'authority: msazure.visualstudio.com' \
    -H 'accept: application/json;api-version=5.0-preview.1;excludeUrls=true;enumsAsNumbers=true;msDateFormat=true;noArrayWrap=true' \
    -H 'accept-language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    --cookie "$cookie_str" \
    -H 'origin: https://msazure.visualstudio.com' \
    -H 'pragma: no-cache' \
    -H 'referer: https://msazure.visualstudio.com/_usersSettings/tokens' \
    -H 'sec-ch-ua: "Not_A Brand";v="8", "Chromium";v="120", "Microsoft Edge";v="120"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Linux"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-origin' \
    -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0' \
    -H 'x-tfs-session: 1df1a27d-1cc2-4735-b8a6-e345c8e0cbe7' \
    -H 'x-vss-reauthenticationaction: Suppress' \
    --data-raw '{"contributionIds":["ms.vss-token-web.personal-access-token-issue-session-token-provider"],"dataProviderContext":{"properties":{"displayName":"'$tokenname'","validTo":"'$validto'","scope":"'$scope'","targetAccounts":["41bf5486-7392-4b7a-a7e3-a735c767e3b3"],"sourcePage":{"url":"https://msazure.visualstudio.com/_usersSettings/tokens","routeId":"ms.vss-admin-web.user-admin-hub-route","routeValues":{"adminPivot":"tokens","controller":"ContributedPage","action":"Execute","serviceHost":"41bf5486-7392-4b7a-a7e3-a735c767e3b3 (msazure)"}}}}}' | tee /dev/stderr | json2table /dataProviders/ms.vss-token-web.personal-access-token-issue-session-token-provider/token -p
  return $status
end

# use this sample function for testing. 
function make_web_req_sample
    echo "VAL: g5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx3a|"
end

function GenNewToken
    echo "Generating new token..." 1>&2
    set -l token (make_web_req | cut -d ' ' -f 2 | tr -d '|')
    or return 1
    test "$token" != ""
    or return 1
################################### Starting ChatGPT generated code ##############################
    set -l creation_time (date +%s)
    echo "$token $creation_time" > $token_cache_file
end

# Function to check if token is still valid and print it if valid
function is_cache_valid
    if test -f $token_cache_file
        set -l token_creation_time (cut -d ' ' -f 2 $token_cache_file)
        set -l current_time (date +%s)
        set -l time_difference (math "$current_time - $token_creation_time")

        # Token expires after 6.5 days (6 * 24 * 60 * 60 + 12 * 60 * 60)
        if test $time_difference -lt 561600
            return 0  # Token is valid
        else
            return 1  # Token expired
        end
    else
        return 1  # Token file doesn't exist, treat as expired
    end
end

function print_token_cache
    set -l token (cut -d ' ' -f 1 $token_cache_file)
    echo $token
end

# Main script logic
if not is_cache_valid
    GenNewToken
    or return $status
end

print_token_cache

