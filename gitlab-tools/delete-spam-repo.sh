# gitlab cleanup spam repos

# this token has already expired. dont waste time try.
token="$glpat"
regex='/.*[0-9][0-9][0-9][0-9].*.git$'
[[ $token = "" ]] && echo ERROR MISSING TOKEN && exit 1

echo > /tmp/.list
for i in {1..100}; do
    curl "https://git.recolic.net/api/v4/projects?private_token=$token&per_page=100&page=$i" | json2table /http_url_to_repo -p | cut -d ' ' -f 2 | tr -d '|' | grep "$regex" >> /tmp/.list || break
done

echo "PLEASE modify this file, leave everything you want to delete."
echo sleep 3
sleep 3

vim /tmp/.list

echo "WARNING! WARNING! WARNING! GOING TO DELETE REPO in 10 SEC."
echo "WARNING! WARNING! WARNING! GOING TO DELETE REPO in 10 SEC."
echo "WARNING! WARNING! WARNING! GOING TO DELETE REPO in 10 SEC."
echo "WARNING! WARNING! WARNING! GOING TO DELETE REPO in 10 SEC."
echo "WARNING! WARNING! WARNING! GOING TO DELETE REPO in 10 SEC."
sleep 10 || exit $?

while read p; do
    echo "DEL! $p"
    sleep 1
    proj_code=`echo "$p" | sed 's|^.*git.recolic.net/||g' | sed 's/.git//' | sed 's|/|%2F|'`
    curl -H "Private-Token: $token" -X DELETE https://git.recolic.net/api/v4/projects/"$proj_code"
done < /tmp/.list


