#!/system/bin/sh

alias lpadd="./bin/lpadd"
alias lpdump="./bin/lpdump"
alias lpflash="./bin/lpflash"
alias lpmake="./bin/lpmake"
alias lpunpack="./bin/lpunpack"
alias imjtool="./bin/imjtool"
alias img2simg="./bin/img2simg"
alias simg2img="./bin/simg2img"



function1() {
  echo ""
  echo "Cleaning up workspace..."
  echo ""
  rm -rf ./extracted >/dev/null 2>&1
  rm -rf ./mounted >/dev/null 2>&1
  rm ./imgsize.log >/dev/null 2>&1
  function0
}

function2() {
  echo ""
  echo "Extracting partitons from super.img..."
  echo ""
  imjtool ./super.img extract
  function0
}

function3() {
  echo ""
  echo "Calculating partition sizes..."
  echo ""
  rm imgsize.log >/dev/null 2>&1
  echo ""
  cd extracted/ && stat -c '%n %s' *.img >> ../imgsize.log
  totalimgsize=$(cat ../imgsize.log|awk '{printf"%s""+",$2}'|sed 's/...$//'|bc)
  superimgsize=$(stat -c '%n %s' ../super.img|awk '{print $2}')
  cd .. && echo "\nTotal Image Size: $totalimgsize" >> imgsize.log
  echo "\nSuper Image Size: $superimgsize" >> imgsize.log && cat imgsize.log
  function0
}

function4() {
  ## mount images from extracted onto ./mounted/system
  mkdir -p $(pwd)/mounted/system/vendor >/dev/null 2>&1
  mkdir -p $(pwd)/mounted/system/product >/dev/null 2>&1
  echo ""
  echo "What partition would you like to mount?"
  echo ""
  echo "b) Go back"
  echo ""
  echo "Available images:"
  echo ""
  ls -1 ./extracted | sed -e 's/\.img$//'
  echo ""
  read img_mount_input
  if [[ $img_mount_input == "product_a" ]]; then
    echo ""
    echo "Mounting '$img_mount_input'.img to ./mounted/system/product ..."
    while ! sudo busybox mount -v -o loop $(pwd)/extracted/product_a.img $(pwd)/mounted/system/product
    do
       echo ""
       echo "Attempting to mount '$img_mount_input'.img !"
    done
    echo ""
    echo "Mounted '$img_mount_input' !"
  function4
  fi
  if [[ $img_mount_input == "system_a" ]]; then
    echo ""
    echo "Mounting '$img_mount_input'.img to ./mounted/system ..."
    while ! sudo busybox mount -v -o loop $(pwd)/extracted/system_a.img $(pwd)/mounted/system/
    do
       echo ""
       echo "Attempting to mount '$img_mount_input'.img !"
    done
    echo ""
    echo "Mounted '$img_mount_input' !"
  function4
  fi
  if [[ $img_mount_input == "vendor_a" ]]; then
    echo ""
    echo "Mounting '$img_mount_input'.img to ./mounted/system/vendor ..."
    while ! sudo busybox mount -v -o loop $(pwd)/extracted/vendor_a.img $(pwd)/mounted/system/vendor
    do
       echo ""
       echo "Attempting to mount '$img_mount_input'.img !"
    done
    echo ""
    echo "Mounted '$img_mount_input' !"
  function4
  fi
  if [[ $img_mount_input == [b] ]]; then
    function0
  fi
}

function5() {
  ## unmount images from mounted dir
  echo ""
  echo "What partition would you like to unmount?"
  echo ""
  echo "b) Go back"
  echo ""
  echo "Currently mounted:"
  echo ""
  sudo busybox mount | grep /mounted/ | awk '{print $3}' | sed 's/.*\///'
  echo ""
  read img_unmount_input
  if [[ $img_unmount_input == "product" ]]; then
    while ! sudo busybox umount -v -f $(pwd)/mounted/system/product
    do
       echo ""
       echo "Attempting to unmount '$img_unmount_input' from ./mounted/system/product !"
    done
    echo ""
    echo "Unmounted '$img_unmount_input' !"
  function5
  fi
  if [[ $img_unmount_input == "system" ]]; then
    while ! sudo busybox umount -v -f $(pwd)/mounted/system
    do
       echo ""
       echo "Attempting to unmount '$img_unmount_input' from ./mounted/system !"
    done
    echo ""
    echo "Unmounted '$img_unmount_input' !"
  function5
  fi
  if [[ $img_unmount_input == "vendor" ]]; then
    while ! sudo busybox umount -v -f $(pwd)/mounted/system/vendor
    do
       echo ""
       echo "Attempting to unmount '$img_unmount_input' from ./mounted/system/product !"
    done
    echo ""
    echo "Unmounted '$img_unmount_input' !"
  function5
  fi
  if [[ $img_unmount_input == [b] ]]; then
    function0
  fi
}

function6() {
  ## create super from imgsize.log
  lpmake --metadata-size 65536 \
 --super-name super \
 --metadata-slots 1 \
 --device super:4831838208 \
 --group main:4829741056 \
 --partition system:readonly:3470016000:main --image system=./system.img \
 --partition vendor:readonly:567001600:main --image vendor=./vendor.img \
 --partition product:readonly:681574400:main --image product=./product.img \
 --sparse \
 --output ./super.img
}

function0() {
  echo ""
  echo "x===========================================x"
  echo "| 1) Cleanup 2) Extract Super 3) Image Size |"
  echo "| 4) Mount IMG 5) Unmount IMG 6) Make Super |"
  echo "| q) Quit                                   |"
  echo "x===========================================x"
  echo ""
  read input
  if [[ $input = [0123456] ]]; then
    function"$input"
  fi
  if [[ $input = [q] ]]; then
    exit 0
  fi
}

function0
