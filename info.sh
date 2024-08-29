#!/system/bin/sh

source $(realpath .env)

buildfp=$(getprop ro.system.build.fingerprint)

brand=$(getprop ro.product.brand)
device_name=$(getprop ro.product.device)
android_version=$(getprop ro.build.version.release)

build_id=$(getprop ro.build.id)
build_version=$(getprop ro.build.version.incremental)

securitypatch=$(getprop ro.build.version.security_patch)
kernel_ver=$(getprop ro.kernel.version)
soc_model_name=$(getprop ro.vendor.soc.model.external_name)
soc_manufacturer=$(getprop ro.soc.manufacturer)
board=$(getprop ro.product.board)
encryption_state=$(getprop ro.crypto.state)

#ascii_box "$buildfp"
echo "Brand:              $brand"
echo "Device Name:        $device_name"
echo "Android Version:    $android_version"
echo ""
echo "Build:              $build_id"
echo "Build Version:      $build_version"
echo ""
echo "SoC Manufacturer:   $soc_manufacturer"
echo "SoC Name:           $soc_model_name"
echo "Board Name:         $board"
echo "Security Patch:     $securitypatch"
echo "Kernel Version:     $kernel_ver"
echo "Encryption State:   $encryption_state"
