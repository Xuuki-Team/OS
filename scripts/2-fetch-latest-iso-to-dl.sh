#!/bin/bash

# Fetch the latest ISO release date
iso_url="https://archlinux.uk.mirror.allworldit.com/archlinux/iso/"
echo "Fetching from $iso_url..."

# Fetch the page content and filter directories
latest_iso_dir=$(curl -s "$iso_url" | grep -oP 'href="\K\d{4}\.\d{2}\.\d{2}/' | sort -r | head -n 1)

# Check if latest_iso_dir is empty
if [[ -z "$latest_iso_dir" ]]; then
    echo "Error: Could not find any ISO release dates."
    exit 1
fi

# Remove trailing slash from directory name
latest_iso_dir=${latest_iso_dir%/}

# Construct the filenames and URLs
iso_file="archlinux-${latest_iso_dir}-x86_64.iso"
sig_file="archlinux-${latest_iso_dir}-x86_64.iso.sig"

iso_download_url="${iso_url}${latest_iso_dir}/${iso_file}"
sig_download_url="${iso_url}${latest_iso_dir}/${sig_file}"

# Check if files already exist
if [[ -f "$iso_file" && -f "$sig_file" ]]; then
    echo "You already have the latest ISO and signature files."
    echo "$iso_file"
    echo "$sig_file"
else
    echo "Latest ISO release: $latest_iso_dir"
    echo "To download the ISO and signature, running wget..."

    # Download the ISO and .sig files if they don't exist
    wget "$iso_download_url"
    wget "$sig_download_url"
fi
