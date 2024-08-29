#!/system/bin/sh
#
# Script Name: Recovery Flashable OTA .ZIP Builder
# Author: Jacy Kincade (1ndevelopment@protonmail.com)
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
# Description: Create custom recovery flashable .zip files
#

source $(realpath .env)

# Functiom to package OTA
run_function() {
    echo "\nCompressing super.img..."
    tar --use-compress-program="$pigz -9 -p$(nproc)" -cf ./Firmware/super.tar.gz ./Firmware/super.img
    mv ./Firmware/super.img ./
    echo "\nArchiving OTA .zip..."
    $p7zip a -tzip stock-ota.zip bin Firmware META-INF
    echo "\nCleaning up..."
    rm -r ./Firmware/super.tar.gz
    mv ./super.img ./Firmware/
}

# Main script execution
detect_env
run_function
