#!/bin/bash                                                                                                     
                                                                                                                
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
