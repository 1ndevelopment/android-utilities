#!/system/bin/sh

export PATH="/data/adb/magisk:/data/adb/magisk/exfat:$PATH"
alias su="/system/bin/magisk su"

# Remove linked binary from /system/bin/
su -c "rm /data/adb/magisk/exfat/dumpexfat"
su -c "rm /data/adb/magisk/exfat/exfatfsck"
su -c "rm /data/adb/magisk/exfat/exfatlabel"
su -c "rm /data/adb/magisk/exfat/mkexfatfs"
su -c "rm /data/adb/magisk/exfat/mount.exfat-fuse"

# Remove exfat & ntfs binaries
su -c "rm /data/adb/magisk/exfat/mount.exfat"
su -c "rm /data/adb/magisk/exfat/ntfs-3g"
su -c "rm /data/adb/magisk/exfat/ntfsfix"
su -c "rm /data/adb/magisk/exfat/probe"

# Remove exfat bin dir
su -c "rm -r /data/adb/magisk/exfat"
