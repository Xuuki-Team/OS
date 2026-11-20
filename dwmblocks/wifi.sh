#!/bin/bash

# Show Wi-Fi icon based on connectivity
if ping -c1 -W1 8.8.8.8 &>/dev/null; then
    echo "  "  # connected
else
    echo " 󰖪 "  # disconnected
fi
