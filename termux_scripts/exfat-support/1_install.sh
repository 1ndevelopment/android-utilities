#!/system/bin/sh

export PATH="/data/adb/magisk:/data/adb/magisk/exfat:$PATH"
alias su="/system/bin/magisk su"

# give permissiom to mount and unmount upon boot
su -c "magiskpolicy --live 'allow sdcardd unlabeled dir { append create execute write relabelfrom link unlink ioctl getattr setattr read rename lock mounton quotaon swapon rmdir audit_access remove_name add_name reparent execmod search open }'" >/dev/null 2>&1
su -c "magiskpolicy --live 'allow sdcardd unlabeled file { append create write relabelfrom link unlink ioctl getattr setattr read rename lock mounton quotaon swapon audit_access open }'" >/dev/null 2>&1
su -c "magiskpolicy --live 'allow unlabeled unlabeled filesystem associate'" >/dev/null 2>&1
su -c "magiskpolicy --live 'allow sdcardd unlabeled filesystem { getattr mount remount unmount }'" >/dev/null 2>&1
su -c "magiskpolicy --live 'allow vold unlabeled filesystem { getattr mount remount unmount }'" >/dev/null 2>&1
su -c "magiskpolicy --live 'allow init unlabeled filesystem { getattr mount remount unmount }'" >/dev/null 2>&1

# Copy exfat & ntfs binaries
su -c "mkdir -p /data/adb/magisk/exfat/"
su -c "cp ./mount.exfat /data/adb/magisk/exfat/"
su -c "cp ./ntfs-3g /data/adb/magisk/exfat/"
su -c "cp ./ntfsfix /data/adb/magisk/exfat/"
su -c "cp ./probe /data/adb/magisk/exfat/"

# Allow read/write for binaries
su -c "chmod 755 /data/adb/magisk/exfat/mount.exfat"
su -c "chmod 755 /data/adb/magisk/exfat/ntfs-3g"
su -c "chmod 755 /data/adb/magisk/exfat/ntfsfix"
su -c "chmod 755 /data/adb/magisk/exfat/probe"

# Link binary to /data/adb/magisk/exfat/ for the all-in-one build
su -c "ln -s /data/adb/magisk/exfat/mount.exfat /data/adb/magisk/exfat/dumpexfat"
su -c "ln -s /data/adb/magisk/exfat/mount.exfat /data/adb/magisk/exfat/exfatfsck"
su -c "ln -s /data/adb/magisk/exfat/mount.exfat /data/adb/magisk/exfat/exfatlabel"
su -c "ln -s /data/adb/magisk/exfat/mount.exfat /data/adb/magisk/exfat/mkexfatfs"
su -c "ln -s /data/adb/magisk/exfat/mount.exfat /data/adb/magisk/exfat/mount.exfat-fuse"
