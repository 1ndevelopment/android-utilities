#!/usr/bin/env sh

# Function to detect the CPU architecture
detect_architecture() {
    uname -m
}

# Function to run the appropriate binary based on the architecture
export_env() {
    arch="$1"
    binary_path=""

    case "$arch" in
        x86_64)
            binary_path="$(pwd)/bin/x86_64/"
            ;;
        i386|i686)
            binary_path="$(pwd)/bin/x86/"
            ;;
        armv7l)
            binary_path="$(pwd)/bin/armv7l/"
            ;;
        aarch64)
            binary_path="$(pwd)/bin/aarch64/"
            ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    if [ -x "$binary_path" ]; then
        export PATH=$binary_path:$PATH
    else
        echo "Binary for architecture $arch not found or not executable"
        exit 1
    fi
}

# Functiom to package OTA
run_function() {
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
}

# Main script execution
architecture=$(detect_architecture)
export_env "$architecture"
run_function
