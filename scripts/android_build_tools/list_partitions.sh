#!/usr/bin/env sh

sort_partitions() {
input=$1
cd $input
for f in *; do
    if [ -L "$f" ]; then
        echo "$(pwd)/$(basename "$f") -> $(readlink "$f")"
    else
        echo "$(pwd)/$(basename "$f")"
    fi
done
}

print_partitions() {
    local input_dir="$1"
    local current_dir=$(pwd)

    echo "\nNavigating to:\n$input_dir"
    cd "$input_dir" || return 1

    echo "\nRaw Partition <- Partition Name\n"
    find . -maxdepth 1 -type l -printf "%l <- %p\n" | sort | sed "s| \./| |"
    echo "\nPartition Name ->  Raw Partition\n"
    find . -maxdepth 1 -type l -printf "%p -> %l\n" | sort -k2 | sed "s|^\./| |"

    echo "\n==============================================================================="

    # Return to the original directory
    cd "$current_dir" || return 1
}

#sort_partitions "/dev/block/by-name"

#print_partitions $1

print_partitions "/dev/block/by-name/"

#print_partitions "/dev/block/mapper/"

#print_partitions "/dev/block/platform/bootdevice/by-name/"
