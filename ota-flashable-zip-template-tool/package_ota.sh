#!/usr/bin/env sh

. ./.env

# Functiom to package OTA
run_function() {
    echo "\nCompressing super.img..."
    tar --use-compress-program="$pigz -9 -p$(nproc)" -cf ./Firmware/super.tar.gz ./Firmware/super.img
    mv ./Firmware/super.img ./
    echo "\nArchiving OTA .zip..."
    "$7z" a -tzip stock-ota.zip bin Firmware META-INF
    echo "\nCleaning up..."
    rm -r ./Firmware/super.tar.gz
    mv ./super.img ./Firmware/
}

# Main script execution
export_env
run_function
