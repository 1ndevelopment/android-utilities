#!/system/bin/sh

build=$(getprop ro.system.build.id)
sysname=$(getprop ro.product.system.name)
buildfp=$(getprop ro.system.build.fingerprint)
securitypatch=$(getprop ro.build.version.security_patch)

echo "$sysname // $build // $securitypatch"
echo "$buildfp"
echo ""

