#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for 7z and pigz
if ! command_exists 7z; then
    echo "7z is not installed. Installing..."
    sudo apt update
    sudo apt install -y p7zip-full
else
    echo "7z is already installed."
fi

if ! command_exists pigz; then
    echo "pigz is not installed. Installing..."
    sudo apt update
    sudo apt install -y pigz
else
    echo "pigz is already installed."
fi
echo ''
echo "Both 7z and pigz are installed. Proceeding with further commands..."


echo ''
echo "Compressing super.img..."
tar --use-compress-program="pigz -9 -p$(nproc)" -cf ./Firmware/super.tar.gz ./Firmware/super.img
mv ./Firmware/super.img ./

echo ''
echo "Archiving OTA .zip..."
7z a -tzip stock-ota.zip bin Firmware META-INF

echo ''
echo "Cleaning up..."
rm -r ./Firmware/super.tar.gz
mv ./super.img ./Firmware/
