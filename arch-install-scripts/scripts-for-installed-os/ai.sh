#!/bin/bash

# Create a virtual environment run manuall
echo "python -m venv ~/ai"
# 
# # Activate the virtual environment 
# source ~/ai/bin/activate
# 
# install shell-gpt in the virtual environment
# pip install shell-gpt
# 

get_openai_api_key() {                                                                                    
    local item_id="c2e2768b-be51-41e8-a2c8-b1ec011f086a"                                                  
    local notes=$(bw get item "$item_id" | jq -r '.notes')                                                
    echo "$notes"                                                                                         
}                                                                                                         
                                                                                                          
# Check if the script is asking for the OpenAI API key                                                    
if sgpt | grep -q "Please enter your OpenAI API key:"; then                                      
    # Get the OpenAI API key from Bitwarden                                                               
    api_key_export=$(get_openai_api_key)                                                                  
    echo "Retrieved notes: $api_key_export"                                                               
                                                                                                          
    # Export the OpenAI API key                                                                           
    eval "$api_key_export"                                                                                
    echo "OpenAI API key has been set."                                                                   
else                                                                                                      
    echo "No API key prompt detected."                                                                    
fi                                                                                                        
