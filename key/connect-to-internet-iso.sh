#!/bin/bash                                                                                                                                                                                             
source ./config.sh
iwctl --passphrase="$PASSWORD" station wlan0 connect "$SIDD" 
