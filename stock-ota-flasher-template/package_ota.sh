#!/bin/bash

# Check if 7z is installed
if ! command -v 7z &> /dev/null; then
    echo "7-Zip is not installed. Installing..."
    # Update package list and install p7zip
    sudo apt update && sudo apt install -y p7zip-full
    if [ $? -ne 0 ]; then
        echo "Failed to install 7-Zip. Exiting."
        exit 1
    fi
else
    echo "7-Zip is installed."
fi

echo "Archiving OTA .zip..."
7z a -tzip stock-ota.zip bin Firmware image META-INF
