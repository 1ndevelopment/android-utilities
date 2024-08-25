#!/usr/bin/env bash

#
# Script Name: Bulk APK Installer (Root)
# Author: Jacy Kincade (1ndev)
#
# License: GPL
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.
#
# Description: Bulk install both individual & split APK files at once
#


. ./.env

show_help() {
    echo ""
    echo "Usage: $0 [options] <directory>"
    echo "Options:"
    echo "  -h, --help  |  Show help"
    echo "  -d, --directory  |  Specify the directory containing the APK files"
    echo ""
    echo "Example:"
    echo "  $0 --directory ~/apks"
    echo ""
    echo "Split APK's must be in their own sub directory"
    echo "<apk-dir>/com.application.name/subdir/*.apk"
    echo ""
    exit 0
}

# Set the directory containing the APK files
while [[ "$1" == -* ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -d|--directory)
            apk_dir="$2"
            shift
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

# Check if aapt & libexpat exists
if command -v aapt &> /dev/null; then
    echo "aapt is installed!"
else
    echo "aapt not installed! Please install aapt & libexpat"
    exit 1
fi

# Function to install a single APK
install_apk() {
    local apk_path="$1"
    local package_name=$(sudo aapt dump badging "$apk_path" | grep package | awk -F"'" '{print $2}')

    ascii_box  "Installing $package_name..."

    if sudo pm install "$apk_path"; then
        ascii_box "Installed $package_name!"
    else
        ascii_box "Failed to install $package_name ..."
    fi
}

# Function to install multiple part APK files
install_split_apk() {
    local apk_dir="$1"
    local package_name=$(sudo aapt dump badging "$apk_dir"/*.apk | grep package | awk -F"'" '{print $2}')

    ascii_box "Installing split APK: $package_name..."

    local APK_TOTAL_SIZE=$(ls -l $apk_dir/././ | awk '{sum+=$5} END {print sum}')

    cd $apk_dir/././ && sudo pm install-create -S $APK_TOTAL_SIZE >> session.id
    local SESSION_ID=$(cat $apk_dir/././session.id | awk '{gsub(/[\[\]]/,"",$0); print $5}')

    local index=0
    for apk_file in *.apk; do
        local BYTE_SIZE=$(du "$apk_file" | awk '{print $1}')
        sudo pm install-write -S "$BYTE_SIZE" "$SESSION_ID" "$index" "$apk_file"
        index=$((index + 1))
    done

    if sudo pm install-commit "$SESSION_ID"; then
        rm $apk_dir/././session.id
        ascii_box "Installed $package_name!"
    else
        echo "Failed to install $package_name ..."
    fi
}

# Recursive function to install APKs in a directory and subdirectories
install_apks_recursive() {
    local dir="$1"

    shopt -s nullglob
    for entry in "$dir"/*.apk; do
        if [ -f "$entry" ]; then
            install_apk "$entry"
        fi
    done

    for entry in "$dir"/*/*/; do
        if [ -d "$entry" ]; then
            install_split_apk "$entry"
        fi
    done
}

# Check if the directory is provided as an argument
if [ -z "$apk_dir" ]; then
    echo ""
    echo "   ___       ____     ___   ___  __ __  ____         __       ____"
    echo "  / _ )__ __/ / /__  / _ | / _ \/ //_/ /  _/__  ___ / /____ _/ / /__ ____"
    echo " / _  / // / /  '_/ / __ |/ ___/ ,<   _/ // _ \(_-</ __/ _ \`/ / / -_) __/"
    echo "/____/\_,_/_/_/\_\ /_/ |_/_/  /_/|_| /___/_//_/___/\__/\_,_/_/_/\__/_/"
    echo "                                                      *root required!"
    echo ""
    echo "Please provide a directory containing the APK files as an argument."
    show_help
    exit 1
fi

# Check if the directory exists
if [ ! -d "$apk_dir" ]; then
    echo "Directory not found: $apk_dir"
    exit 1
fi

# Install APKs recursively
install_apks_recursive "$apk_dir"

