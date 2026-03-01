#!/bin/bash

# Fetch the latest ISO release date
iso_url="https://archlinux.uk.mirror.allworldit.com/archlinux/iso/"
echo "Fetching from $iso_url..."

# Fetch the page content and filter directories
latest_iso=$(curl -s "$iso_url" | grep -oP 'href="\K\d{4}\.\d{2}\.\d{2}/' | sort -r | head -n 1)

# Check if latest_iso is empty
if [[ -z "$latest_iso" ]]; then
    echo "Error: Could not find any ISO release dates."
    exit 1
fi

# Output the latest ISO
echo "Latest ISO release: $latest_iso"

