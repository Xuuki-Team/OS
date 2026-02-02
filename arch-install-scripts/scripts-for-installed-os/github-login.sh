#!/bin/bash

# Retrieve the GitHub token from Bitwarden
GH_TOKEN=$(bw get item e695061e-5f46-46b3-a40c-b1d2011f7fe3 | jq -r '.notes' | sed 's/GH_TOKEN=//' | tr -d '"')

# Check if the token was retrieved successfully
if [ -z "$GH_TOKEN" ]; then
  echo "Failed to retrieve GitHub token from Bitwarden."
  exit 1
fi

# Log into GitHub using the GitHub CLI
echo $GH_TOKEN | gh auth login --with-token

# Set the git protocol to SSH
gh config set -h github.com git_protocol ssh

echo "GitHub CLI login and configuration completed."
