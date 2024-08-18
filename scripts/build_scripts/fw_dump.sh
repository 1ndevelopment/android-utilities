#!/system/bin/sh

build=$(getprop ro.system.build.id)
sysname=$(getprop ro.product.system.name)
buildfp=$(getprop ro.system.build.fingerprint)
securitypatch=$(getprop ro.build.version.security_patch)

echo "$sysname // $build // $securitypatch"
echo "$buildfp"
echo ""

# Define RAW_FW as an array
read -r -d '' RAW_FW << EOM
/dev/block/bootdevice/by-name/boot_a
/dev/block/bootdevice/by-name/boot_b
/dev/block/bootdevice/by-name/boot_para
/dev/block/bootdevice/by-name/dtbo_a
/dev/block/bootdevice/by-name/dtbo_b
/dev/block/bootdevice/by-name/expdb
/dev/block/bootdevice/by-name/flashinfo
/dev/block/bootdevice/by-name/frp
/dev/block/bootdevice/by-name/gz_a
/dev/block/bootdevice/by-name/gz_b
/dev/block/bootdevice/by-name/init_boot_a
/dev/block/bootdevice/by-name/init_boot_b
/dev/block/bootdevice/by-name/lk_a
/dev/block/bootdevice/by-name/lk_b
/dev/block/bootdevice/by-name/logo
/dev/block/bootdevice/by-name/md1img_a
/dev/block/bootdevice/by-name/md1img_b
/dev/block/bootdevice/by-name/md_udc
/dev/block/bootdevice/by-name/metadata
/dev/block/bootdevice/by-name/nvcfg
/dev/block/bootdevice/by-name/nvdata
/dev/block/bootdevice/by-name/nvram
/dev/block/bootdevice/by-name/otp
/dev/block/bootdevice/by-name/para
/dev/block/bootdevice/by-name/persist
/dev/block/bootdevice/by-name/preloader_a
/dev/block/bootdevice/by-name/preloader_b
/dev/block/bootdevice/by-name/preloader_raw_a
/dev/block/bootdevice/by-name/preloader_raw_b
/dev/block/bootdevice/by-name/proinfo
/dev/block/bootdevice/by-name/protect1
/dev/block/bootdevice/by-name/protect2
/dev/block/bootdevice/by-name/scp_a
/dev/block/bootdevice/by-name/scp_b
/dev/block/bootdevice/by-name/sec1
/dev/block/bootdevice/by-name/seccfg
/dev/block/bootdevice/by-name/spmfw_a
/dev/block/bootdevice/by-name/spmfw_b
/dev/block/bootdevice/by-name/sspm_a
/dev/block/bootdevice/by-name/sspm_b
/dev/block/bootdevice/by-name/tee_a
/dev/block/bootdevice/by-name/tee_b
/dev/block/bootdevice/by-name/vbmeta_a
/dev/block/bootdevice/by-name/vbmeta_b
/dev/block/bootdevice/by-name/vbmeta_system_a
/dev/block/bootdevice/by-name/vbmeta_system_b
/dev/block/bootdevice/by-name/vbmeta_vendor_a
/dev/block/bootdevice/by-name/vbmeta_vendor_b
/dev/block/bootdevice/by-name/vendor_boot_a
/dev/block/bootdevice/by-name/vendor_boot_b
EOM

# Convert RAW_FW string into an array of names
readarray -t FW_NAMES <<< "$(echo "$RAW_FW" | awk -F'/' '{print $NF}')"

RAW_FW_PATH="/dev/block/bootdevice/by-name/"
OUTPUT_PATH=$1

# Check if OUTPUT_PATH is provided and is a directory
if [[ -z "$OUTPUT_PATH" || ! -d "$OUTPUT_PATH" ]]; then
    echo "Output path is not provided or does not exist."
    exit 1
fi

# Iterate over firmware names and use dd to dump each one
for fw_name in "${FW_NAMES[@]}"; do
    echo "Converting $fw_name to $OUTPUT_PATH$fw_name.img ..."
    dd if="$RAW_FW_PATH$fw_name" of="$OUTPUT_PATH$fw_name.img" bs=4096
    # Check if dd command was successful
    if [ $? -ne 0 ]; then
        echo "Error dumping $fw_name to $OUTPUT_PATH$fw_name.img"
    else
        echo "Successfully dumped $fw_name to $OUTPUT_PATH$fw_name.img"
    fi
    echo ""
done
