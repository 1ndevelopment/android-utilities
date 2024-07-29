LOOP_DEVICE=$(sudo losetup -f) && sudo losetup $LOOP_DEVICE ./system_a.img && sudo mount -t ext4 -o rw $LOOP_DEVICE ./system_a
cd system_a/system/app
rm -r ZooFriends WorldNews Sudoku Solitaire WoodyUnblockSlidePuzzle HexBlocks Celebs WordSwipeWorldTourConnect
cd ../bin
cp ~/../android-utilities/bin/arm64/7zzs ./7z
cp ~/../android-utilities/bin/arm64/parted .
cd ../../..
umount ./system_a
LOOP_DEVICE=$(sudo losetup -f) && sudo losetup $LOOP_DEVICE ./product_a.img && sudo mount -t ext4 -o rw $LOOP_DEVICE ./product_a
cd product_a/app
rm -r Chrome Gmail2 Keep Photos Videos YouTube YTMusic Meet
cd ../priv-app
rm -r PersonalSafety
cd ../..
umount ./product_a
LOOP_DEVICE=$(sudo losetup -f) && sudo losetup $LOOP_DEVICE ./vendor_a.img && sudo mount -t ext4 -o rw $LOOP_DEVICE ./vendor_a
umount ./vendor_a
