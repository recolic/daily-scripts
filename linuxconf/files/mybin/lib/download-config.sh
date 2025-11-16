set -o pipefail

# Expect shadowrocket style API
declare -a API_URLS=(
    'https://SECRET_3'
    'https://SECRET_3lw'
)

for URL in "${API_URLS[@]}"; do
    echo "DOWNLOADING URL SUBS : $URL"

    curl "$URL" | base64 -d | dos2unix | while IFS= read -r line; do
        echo "DECODING: $line"
        echo "$line" | python vmess2json.py --inbounds socks:10808 -o output.json
        [[ -s output.json ]] || ! echo "Skip non-subscription line" || continue

        fname=proxy-url-to-name.py
    
        if [[ -f "$fname" ]]; then
            nodename=`echo "$line" | grep -o '#[^#]*$' | tr -d '#'`
            fname=`name_simplify "$nodename"`.json
        fi
    
        mv output.json "$fname"
    done || exit $?

done || exit $?
