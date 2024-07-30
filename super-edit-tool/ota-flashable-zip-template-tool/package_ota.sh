#!/usr/bin/env sh

# Function to run the appropriate binary based on the architecture
export_env() {
    arch=$(uname -m)
    binary_path=""

    case "$arch" in
        x86_64) binary_path="$(pwd)/bin/x86_64/" ;;
        i386|i686) binary_path="$(pwd)/bin/x86/" ;;
        armv7l) binary_path="$(pwd)/bin/armv7l/" ;;
        aarch64) binary_path="$(pwd)/bin/aarch64/" ;;
        *) echo "Unsupported architecture: $arch" ; exit 1 ;;
    esac
    [ -x "$binary_path" ] && { export PATH=$binary_path:$PATH }
        echo "Binary for architecture $arch not found or not executable"
        exit 1
}

# Functiom to package OTA
run_function() {
    echo "\nCompressing super.img..."
    tar --use-compress-program="pigz -9 -p$(nproc)" -cf ./Firmware/super.tar.gz ./Firmware/super.img
    mv ./Firmware/super.img ./
    echo "\nArchiving OTA .zip..."
    7z a -tzip stock-ota.zip bin Firmware META-INF
    echo "\nCleaning up..."
    rm -r ./Firmware/super.tar.gz
    mv ./super.img ./Firmware/
}

# Main script execution
export_env
run_function
