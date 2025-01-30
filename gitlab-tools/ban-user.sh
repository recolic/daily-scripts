#!/bin/bash

# GitLab instance and PAT
GITLAB_INSTANCE="https://git.recolic.net"
PAT="$glpat"

# File containing the list of emails to be banned
EMAIL_LIST="$1"

[[ $1 = "" ]] && echo MISSINGARG && exit 1
[[ $PAT = "" ]] && echo NO_PAT && exit 1

# Loop through each email in the list
while IFS= read -r email; do
  # Fetch the user ID by email
  USER_ID=$(curl --silent --header "PRIVATE-TOKEN: $PAT" "$GITLAB_INSTANCE/api/v4/users?search=$email" | jq -r '.[0].id')
  
  # Check if a valid user ID was found
  if [ "$USER_ID" != "null" ]; then
    # Ban the user by their ID
    curl --request POST --silent --header "PRIVATE-TOKEN: $PAT" "$GITLAB_INSTANCE/api/v4/users/$USER_ID/ban"
    echo "Banned user with email: $email (ID: $USER_ID)"
  else
    echo "No user found with email: $email"
  fi
done < "$EMAIL_LIST"

