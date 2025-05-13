#!/bin/bash

# Input file with list of emails (provided as parameter)
EMAIL_LIST="$1"

# Output files
OUT1="blackHIT.txt"
OUT2="notHIT.txt"

# Placeholder keywords (to be filled later)
KEYWORD1="This server could not verify that you"
KEYWORD2="wp-content/cache/wpo-minify"
BLACKLIST_REGEX="proofcatch.net|claychoen.top"
WHITELIST_REGEX="outlook.com|gmail.com|hust.edu.cn|qq.com|hotmail.com|protonmail.com|recolic"

# Empty the output files if they already exist
> "$OUT1"
> "$OUT2"

# Loop through each email in the list
while IFS= read -r email; do
    echo "CHECK $email"

    if echo "$email" | grep -qE "$WHITELIST_REGEX"; then
        echo "$email" >> "$OUT2"
        continue
    elif echo "$email" | grep -qE "$BLACKLIST_REGEX"; then
      echo "$email" >> "$OUT1"
      echo BLACK
      continue
    fi

  # Extract domain from the email
  domain=$(echo "$email" | awk -F'@' '{print $2}')
  
  # Fetch the homepage using curl
  response=$(curl --silent --max-time 10 "http://$domain" -L)

  # Check if the response contains KEYWORD1 or KEYWORD2
  if echo "$response" | grep -qE "$KEYWORD1|$KEYWORD2"; then
      echo BLACK
    echo "$email" >> "$OUT1"
  else
    echo "$email" >> "$OUT2"
  fi

done < "$EMAIL_LIST"

echo "Emails processed. Results saved to $OUT1 and $OUT2."

