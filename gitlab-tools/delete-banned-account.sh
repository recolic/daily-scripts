#!/bin/bash

# GitLab instance and PAT
GITLAB_INSTANCE="https://git.recolic.net"
PAT="$glpat"

# Pagination settings
PAGE=1
PER_PAGE=100

# Loop through paginated results to get all blocked users
while :; do
  RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PAT" "$GITLAB_INSTANCE/api/v4/users?page=$PAGE&per_page=$PER_PAGE") || echo CURL FAIL
  
  # Check if the response is empty, meaning we've fetched all the pages
  if [ "$(echo $RESPONSE | wc -c)" -le 5 ]; then
    break
  fi
  
  # Extract the user ID and email of each blocked user
  for USER_DATA in $(echo "$RESPONSE" | jq -r '.[] | @base64'); do
    _jq() {
      echo "$USER_DATA" | base64 --decode | jq -r "$1"
    }

    USER_ID=$(_jq '.id')
    USER_EMAIL=$(_jq '.email')
    
    # Attempt to unban the user (to check if they are banned)
    UNBAN_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PAT" --request POST "$GITLAB_INSTANCE/api/v4/users/$USER_ID/unban")
    # echo "DEBUG: $UNBAN_RESPONSE"
    
    # Check if the user was actually banned (successful unban)
    if [ "$UNBAN_RESPONSE" = "true" ]; then
      echo "IS BANNED: $USER_EMAIL (ID: $USER_ID) was banned and has been unbanned."
      curl --silent --header "PRIVATE-TOKEN: $PAT" --request POST "$GITLAB_INSTANCE/api/v4/users/$USER_ID/ban"
      echo "BANNED again."
      
      # Check if REAL=1 is set, and delete the user if so
      if [ "$REAL" == "1" ]; then
        echo "Deleting user with email: $USER_EMAIL (ID: $USER_ID)..."
        curl --request DELETE --silent --header "PRIVATE-TOKEN: $PAT" "$GITLAB_INSTANCE/api/v4/users/$USER_ID?hard_delete=true"
      else
        echo "REAL=1 is not set, skipping deletion for user with email: $USER_EMAIL (ID: $USER_ID)"
      fi
    else
      echo "Was not banned: $USER_EMAIL (ID: $USER_ID) , skipping..."
    fi
  done
  
  PAGE=$((PAGE+1))
done

echo "Script execution completed."

