#!/system/bin/sh

rm ramdisk-files.txt && rm ramdisk-files.sha256sum

find . -type f -print0 | xargs -0 ls >> ramdisk-files.tmp

sed 's/..//' ramdisk-files.tmp >> ramdisk-files.txt

rm ramdisk-files.tmp

find . -type f -print0 | xargs -0 sha256sum >> ramdisk-files.sha256sum
