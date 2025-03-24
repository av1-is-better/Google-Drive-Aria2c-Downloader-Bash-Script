#!/bin/bash

# Download directory
DOWNLOAD_DIR="/home/ubuntu/downloads"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0"

# Banner
echo -e "\033[1;96m
░██████╗░░█████╗░░█████╗░░██████╗░██╗░░░░░███████╗  ██████╗░██████╗░██╗██╗░░░██╗███████╗
██╔════╝░██╔══██╗██╔══██╗██╔════╝░██║░░░░░██╔════╝  ██╔══██╗██╔══██╗██║██║░░░██║██╔════╝
██║░░██╗░██║░░██║██║░░██║██║░░██╗░██║░░░░░█████╗░░  ██║░░██║██████╔╝██║╚██╗░██╔╝█████╗░░
██║░░╚██╗██║░░██║██║░░██║██║░░╚██╗██║░░░░░██╔══╝░░  ██║░░██║██╔══██╗██║░╚████╔╝░██╔══╝░░
╚██████╔╝╚█████╔╝╚█████╔╝╚██████╔╝███████╗███████╗  ██████╔╝██║░░██║██║░░╚██╔╝░░███████╗
░╚═════╝░░╚════╝░░╚════╝░░╚═════╝░╚══════╝╚══════╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░░╚═╝░░░╚══════╝\033[0m"

# Check for aria2c
if ! command -v aria2c &> /dev/null; then
    echo -e "\033[1;91mError: aria2c not found. Install it and try again.\033[0m"
    exit 1
fi

# Function to extract Google Drive File ID
extract_drive_id() {
    local url="$1"

    # Extract using multiple regex patterns to handle all possible Google Drive URLs
    echo "$url" | sed -E -n '
        s#.*https://drive\.google\.com/file/d/([^/?]+).*#\1#p;
        s#.*https://drive\.google\.com/open\?id=([^&]+).*#\1#p;
        s#.*https://drive\.google\.com/uc\?export=download&id=([^&]+).*#\1#p;
        s#.*id=([^&]+).*#\1#p;
    '
}

# Function to fetch UUID and Filename using sed
fetch_uuid_and_filename() {
    local file_id="$1"
    local url="https://drive.usercontent.google.com/download?id=${file_id}&export=download"
    local page_content=$(curl -s "$url")

    # Extract UUID using sed
    local uuid=$(echo "$page_content" | sed -n 's/.*name="uuid" value="\([a-f0-9\-]\+\)".*/\1/p')

    # Extract Filename using sed
    local filename=$(echo "$page_content" | sed -n 's/.*<span class="uc-name-size"><a href="[^"]*">\([^<]*\)<\/a>.*/\1/p')

    echo "${uuid}|${filename}"
}

# Prompt user for Google Drive file URL
read -p $'\n\033[1;95mEnter Google Drive File URL: \033[1;94m' file_url
drive_file_id=$(extract_drive_id "$file_url")


# Check if file ID was extracted
if [[ -z "$drive_file_id" ]]; then
    echo -e "\033[1;91mError: Could not extract File ID from the URL. Exiting...\033[0m"
    exit 1
fi

# Fetch UUID and filename
uuid_data=$(fetch_uuid_and_filename "$drive_file_id")
uuid_value=$(echo "$uuid_data" | cut -d '|' -f1)
file_name=$(echo "$uuid_data" | cut -d '|' -f2)

# Check if UUID was found
if [[ -z "$uuid_value" ]]; then
    echo -e "\033[1;91m\nError: UUID not found in the response.\033[0m"
    exit 1
fi
echo -e "\033[1;93m\nDownload UUID: \033[1;95m$uuid_value\033[0m"

# Check if filename was found
if [[ -z "$file_name" ]]; then
    echo -e "\033[1;91mError: Filename not found in the response.\033[0m"
    exit 1
fi
echo -e "\033[1;93mFile Name: \033[1;92m$file_name\033[0m"
echo -e "\033[1;93mDownload Path: \033[1;96m$DOWNLOAD_DIR\033[0m"

# Downloading file using aria2c
echo -e "\033[1;92m\n========================================================================="
echo -e "\033[1;96m                          Download Started  "
echo -e "\033[1;92m=========================================================================\033[0m"

while true; do
    aria2c --max-connection-per-server=4 \
           --continue=true \
           --dir="$DOWNLOAD_DIR" \
           --file-allocation=none \
           --summary-interval=0 \
           --console-log-level=error \
           --user-agent="$USER_AGENT" \
           "https://drive.usercontent.google.com/download?id=$drive_file_id&export=download&authuser=0&confirm=t&uuid=${uuid_value}"

    if [[ $? -eq 0 ]]; then
        echo -e "\033[1;92m\n========================================================================="
        echo -e "\033[1;96m                          Download Completed  "
        echo -e "\033[1;92m=========================================================================\033[0m"
        break
    else
        echo -e "\033[1;91m\nDownload Failed... Retrying\033[0m"
        uuid_data=$(fetch_uuid_and_filename "$drive_file_id")
        uuid_value=$(echo "$uuid_data" | cut -d '|' -f1)
    fi
done
