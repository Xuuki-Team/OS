#!/bin/bash                                                                                                          
                                                                                                                     
# Prompt for email and password                                                                                      
read -p "Email address: " email                                                                                      
read -s -p "Master password: " password                                                                              
echo                                                                                                                 
                                                                                                                     
# Log in to Bitwarden and capture the session key                                                                    
session_key=$(bw login "$email" "$password" --raw)                                                                   
                                                                                                                     
# Check if login was successful                                                                                      
if [ $? -eq 0 ]; then                                                                                                
    echo "Login successful!"                                                                                         
    export BW_SESSION="$session_key"                                                                                 
    echo "BW_SESSION has been set."                                                                                  
else                                                                                                                 
    echo "Login failed."                                                                                             
    exit 1                                                                                                           
fi                                                                                                                   
                                                                                                                     
# Check if .ssh directory exists, if not, create it                                                                  
if [ ! -d "$HOME/.ssh" ]; then                                                                                       
  mkdir -p "$HOME/.ssh"                                                                                              
  echo "Created .ssh directory."                                                                                     
else                                                                                                                 
  echo ".ssh directory already exists."                                                                              
fi                                                                                                                   
                                                                                                                     
# Retrieve the SSH keys from Bitwarden and store them in the .ssh directory                                          
PRIVATE_KEY_ID="e4c3fc3e-4927-47bd-8cec-b1f70165d6f0"                                                                
PUBLIC_KEY_ID="98f79957-2aef-4117-84ee-b1f7016417ae"                                                                 
                                                                                                                     
# Get the private key                                                                                                
bw get item $PRIVATE_KEY_ID | jq -r '.notes' > "$HOME/.ssh/id_ed25519"                                               
chmod 600 "$HOME/.ssh/id_ed25519"                                                                                    
echo "Private key saved to $HOME/.ssh/id_ed25519"                                                                    
                                                                                                                     
# Get the public key                                                                                                 
bw get item $PUBLIC_KEY_ID | jq -r '.notes' > "$HOME/.ssh/id_ed25519.pub"                                            
chmod 644 "$HOME/.ssh/id_ed25519.pub"                                                                                
echo "Public key saved to $HOME/.ssh/id_ed25519.pub"                                                                 
                                                                                                                     
# Initialize git repository and configure remote                                                                     
git init                                                                                                             
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts                                                              
git remote add origin git@github.com:JoelNash-Xuuki/home.git                                                         
git remote -v                                                                                                        
ssh -T git@github.com                                                                                                
                                                                                                                     
# Configure git user                                                                                                 
git config --global user.email "$email"                                                                              
git config --global user.name "Joel Nash"                                                                            
                                                                                                                     
# Fetch and checkout main branch                                                                                     
git fetch origin                                                                                                     
git checkout -b main origin/main                                                                                     
                                                                                                                     
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
