#!/bin/bash

# Prompt for email and password
read -p "Email address: " email
read -s -p "Master password: " password
echo                                                                                                                                                                                                                                        # Log in to Bitwarden and capture the session key
session_key=$(bw login "$email" "$password" --raw)

# Check if login was successful
if [ $? -eq 0 ]; then
    echo "Login successful!"
    export BW_SESSION="$session_key"
    echo "BW_SESSION has been set."
else
    echo "Login failed."
fi
