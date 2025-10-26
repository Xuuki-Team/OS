#!/bin/bash                                                                                                          
                                                                                                                     
# Bitwarden Docker ID                                                                                                
BW_DOCKER_ID="8a1423e6-e4c1-4540-98cc-b1d7002d493c"                                                                  
                                                                                                                     
# Get Docker password from Bitwarden                                                                                 
DOCKER_PASSWORD=$(bw get password $BW_DOCKER_ID)                                     
                                                                                                                     
# Log in to Docker                                                                                                   
echo $DOCKER_PASSWORD | docker login -u xuuki --password-stdin                                                       
                                                                                                                     
# Ensure Docker is running                                                                                           
sudo systemctl start docker                                                                                          
sudo systemctl enable docker                                                                                         
sudo usermod -aG docker $USER                                                                                        
                                                                                                                     
echo "Docker login and setup complete."                                                                              
