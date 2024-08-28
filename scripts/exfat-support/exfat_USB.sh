#!/system/bin/sh

logfile="/data/adb/magisk/exfat/exfat_mount.log"
mount="/data/adb/magisk/exfat/mount.exfat-fuse"
options_rw="rw,uid=1023,gid=1023,umask=0000,noatime"
options_ro="ro,uid=1023,gid=1023,umask=0000"
device="/dev/block/sda1"
dir="/mnt/media_rw/usbotg"

echo '' >> $logfile
echo '******' "$(date)" '******' >> $logfile
echo 'id: ' "$(id)" >> $logfile 2>&1

echo '' >> $logfile
$mount -o $options_rw $device $dir >> $logfile
echo ''
echo 'to unmount the drive, use the command: umount -l $dir '
echo ''
echo 'USB mounted in:'
echo ''
echo '$dir'

