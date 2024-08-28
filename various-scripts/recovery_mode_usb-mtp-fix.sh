###############################
# Create backing file         #
###############################

dd bs=1M count=16 if=/dev/zero of=/tmp/lun0.img
parted /tmp/lun0.img mklabel msdos
parted --align=minimal /tmp/lun0.img mkpart primary fat32 0% 100%
/external_sd/TWRP/bin/busybox mkfs.vfat /tmp/lun0.img

###############################
# Mount file                  #
###############################

losetup /dev/block/loop7 /tmp/lun0.img
mkdir /mnt/usb
mount /dev/block/loop7 /mnt/usb

###############################
# Configure USB gadget        #
###############################
modprobe libcomposite

cd /config/usb_gadget/g1/

###############################
# Populate Device-Level Stuff #
###############################

#echo "0x18d1" > idVendor  # Linux Foundation - must be adopted by your ID
#echo "0xd001" > idProduct # multi gadget - must be adopted by your ProductID

ln -s idVendor /sys/class/android_usb/android0/idVendor
ln -s idProduct /sys/class/android_usb/android0/idProduct

#echo 0x0419 > bcdDevice   # v1.0.0
#echo 0x0200 > bcdUSB      # USB 2.0

# English language strings...
#mkdir strings/0x409

#echo "0123456789" > strings/0x409/serialnumber
#echo "foo" > strings/0x409/manufacturer
#echo "bar" > strings/0x409/product

#mkdir configs/b.1
#mkdir configs/b.1/strings/0x409
echo -e "USB Mass Storage config\nadb" >> configs/b.1/strings/0x409/configuration

#
# Create mass_storage config
#

mkdir functions/mass_storage.0/
mkdir functions/mass_storage.0/lun.0/

# link the mount point which shall be used for usb_mass_storage

echo "/tmp/lun0.img" > /config/usb_gadget/g1/functions/mass_storage.0/lun.0/file
echo 1 > /config/usb_gadget/g1/functions/mass_storage.0/lun.0/removable

# associate function with config
ln -s functions/mass_storage.0 configs/b.1

#bind..
# you need to replace this line with the platform-specific UDC.
# Use 'ls /sys/class/udc' to see available UDCs
echo "musb-hdrc" > UDC
