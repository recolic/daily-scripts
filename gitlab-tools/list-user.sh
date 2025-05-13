#!/bin/bash

# Set your GitLab instance
GITLAB_INSTANCE="https://git.recolic.net"

# Use the already defined PAT variable
PAT="$glpat"
[[ $PAT = "" ]] && echo NO_PAT && exit 1

# Output file for emails
OUTPUT_FILE="user_emails.txt"

# Get all users' emails from GitLab
PAGE=1
PER_PAGE=100  # Adjust the number per page if needed

> "$OUTPUT_FILE"  # Empty the output file if it already exists

while :; do
    echo PAGE=$PAGE
  RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PAT" "$GITLAB_INSTANCE/api/v4/users?page=$PAGE&per_page=$PER_PAGE")
  
  # Check if the response is empty, meaning we've fetched all the pages
  if [ "$(echo $RESPONSE | wc -c)" -le 2 ]; then
    break
  fi
  
  # Extract the email from each user and append to the output file
  echo "$RESPONSE" | jq -r '.[] | .email' >> "$OUTPUT_FILE"
  
  PAGE=$((PAGE+1))
done

echo "User emails have been saved to $OUTPUT_FILE."

