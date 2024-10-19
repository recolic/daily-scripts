#!/bin/bash

# GitLab instance and PAT
GITLAB_INSTANCE="https://git.recolic.net"
PAT="$glpat"

# Check if all required arguments are provided
if [ $# -ne 4 ]; then
  echo "Usage: $0 <name> <username> <email> <password>"
  exit 1
fi

# Assign arguments to variables
NAME="$1"
USERNAME="$2"
EMAIL="$3"
PASSWORD="$4"

# Create user via GitLab API
RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PAT" --request POST "$GITLAB_INSTANCE/api/v4/users" \
  --data "name=$NAME" \
  --data "username=$USERNAME" \
  --data "email=$EMAIL" \
  --data "password=$PASSWORD" \
  --data "skip_confirmation=true")

# Check if the user creation was successful
if echo "$RESPONSE" | grep -q '"id"'; then
  echo "User created successfully: $USERNAME ($EMAIL)"
else
  echo "Failed to create user. Response:"
  echo "$RESPONSE"
fi

