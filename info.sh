#!/system/bin/sh

buildfp=$(getprop ro.system.build.fingerprint)
securitypatch=$(getprop ro.build.version.security_patch)
kernel_ver=$(getprop ro.kernel.version)
soc_model_name=$(getprop ro.vendor.soc.model.external_name)
soc_manufacturer=$(getprop ro.soc.manufacturer)
board=$(getprop ro.product.board)

. ./.env

echo "\n$buildfp\n"
echo "SoC Manufacturer:   $soc_manufacturer"
echo "SoC Name:           $soc_model_name"
echo "Board Name:         $board"
echo "Security Patch:     $securitypatch"
echo "Kernel Version:     $kernel_ver"
echo ""
