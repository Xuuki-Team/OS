#!/bin/bash

# 1. Clean logout to prevent the "already logged in" bug
bw logout 2>/dev/null

# 2. Force a fresh login and capture the key
echo "Logging in to Bitwarden..."
SESSION_KEY=$(bw login --raw)

# 3. If that failed, try unlocking
if [ $? -ne 0 ] || [ -z "$SESSION_KEY" ]; then
    echo "Login failed or already logged in. Attempting unlock..."
    SESSION_KEY=$(bw unlock --raw)
fi

# 4. Critical: Export the key to the environment
if [ -n "$SESSION_KEY" ]; then
    export BW_SESSION="$SESSION_KEY"
    echo "Vault unlocked. Session key active."
else
    echo "Could not retrieve session key. Check your master password."
    exit 1
fi

# 5. Check status - should say "unlocked"
bw status | jq '.status'

# 6. Now run your list (should NOT ask for password now)
bw list items --search "ssh"

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
