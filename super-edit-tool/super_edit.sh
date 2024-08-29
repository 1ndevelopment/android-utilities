#!/system/bin/sh

source $(realpath .env)

cleanup() {
  echo "\nCleaning up workspace...\n"
  clean() { i=$1 ; for o in $i; do [ -e "$o" ] && silence rm -rf "$o" ; done  ; }
  l=$(clean "./$LOG_FILE ./$HASH_FILE ./.tmp.* ./._")
  d=$(clean "./extracted ./mounted ./out")
  $d && $l && echo "\nCleanup completed." || echo "\nCleanup failed!"
  main_menu
}

list_partitions() { sudo find /dev/block/bootdevice/by-name -type l -printf "%p -> " -exec readlink -f {} \; | awk '{print $NF, $0}' | sort | cut -d' ' -f2- ; }

extract_img() {
## Extract super or sub-partitions of super
  if [ -f "./super.img" ]; then
      [ "$start_option" = debug ] && { STATUS="\nInitialized in Debug Mode.\n\nFound super.img" ; } || STATUS="\nInitialized.\n\nFound super.img."
      if silence ls ./extracted/*.img ; then
          STATUS+="\nImages are located in ./extracted \n" && [ "$init_job" -eq 1 ] && { init_job=0 && main_menu ; }
      else
          STATUS+="\nNo partitions have been extracted.\n" && [ "$init_job" -eq 2 ] && { init_job=0 && main_menu ; }
      fi
      echo -n "Extract partitions from super.img ?\n[y/n]: " && read input && echo ""
      case "$input" in
          y) echo "\nExtracting partitons from super.img...\n" && $imjtool super.img extract && init_job=1 && init ;;
          n) init_job=2 ; main_menu ;;
          *) main_menu ;;
      esac
  else
      [ "$start_option" = debug ] && { STATUS="\nInitialized in Debug Mode.\n\nNo super.img found." ; } || STATUS="\nInitialized.\n\nNo super.img found."
      echo -n "\nPull super.img from /dev/block/by-name/super ?\n[y/n]: " && read input && echo ""
      case "$input" in
          y) echo "Dumping /dev/block/by-name/super to ./super.img ..."
              dd if=/dev/block/by-name/super of=./super.img bs=2048 status=progress
              echo "\nsuper.img dumped! \n" && extract_img ;;
          *) main_menu ;;
      esac
  fi
}

mount_img() {
## Mount images from ./extracted/ onto ./mounted/system
  silence mkdir -p ./mounted/system/vendor ./mounted/system/product ./extracted
  mount() {
    LOOP_DEVICE=$(sudo losetup -f)
    #fallocate -l 2G ./extracted/$IMG_NAME.img
    #resize2fs ./extracted/$IMG_NAME.img 2G
    sudo losetup $LOOP_DEVICE ./extracted/$IMG_NAME.img
    sudo mount -t ext4 -o rw $LOOP_DEVICE $MOUNT_POINT
    case "$(mountpoint -q "$MOUNT_POINT"; echo $?)" in
      0) echo "\n$IMG_NAME mounted successfully at: $MOUNT_POINT\n"; main_menu ;;
      *) printf '\nFailed to mount the image\n'; mount_img ;;
    esac
  }
  ascii_box "What partition would you like to mount?"
  echo "\nMountable partitions:\n" && ls -1 ./extracted | sed -e 's/\.img$//'
  echo -n "\nb) Main Menu\n\n>> " && read IMG_NAME && echo ""
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" && mount ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" && mount ;;
    product*) MOUNT_POINT="./mounted/system/product" && mount ;;
    [qb]) echo "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo "\nUnknown image name: $IMG_NAME\n" && mount_img ;;
  esac
}

remove_bloat() {
## Remove apps from super sub-partitons
  func() {
    apps() { ls -1 ./mounted/system/$INPUT/app ; } && APPS=$(apps)
    ascii_box "What apps would you like to remove from $INPUT?" && echo "" && apps
    echo -n "\nb) Change Partition\nq) Main Menu\n\n>> "
    read APP_NAME && echo ""
    DEBLOAT=$(silence rm -r ./mounted/system/$INPUT/app/$APP_NAME)
    for NAME in $APPS; do case "$APP_NAME" in
      b) remove_bloat ;; q) echo "Heading back to Main Menu...\n" && main_menu ;;
      $APP_NAME) echo "\nRemoving $APP_NAME\n" && $DEBLOAT && func ;;
    esac done
  }
  set_global_vars
  ascii_box "What partition would you like to remove bloat from?"
  echo -n "\nCurrently mounted:\n\n$MOUNTED_IMGS\n\nb) Main Menu\n\n>> "
  read INPUT && echo ""
  case "$INPUT" in
    system*) func ;; vendor*) func ;; product*) func ;;
    [qb]) echo "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo "\nUnknown image name: $NAME\n" && remove_bloat ;;
  esac
}

unmount_img() {
## Unmount chosen .img from mount point
  unmount() {
    while ! umount "$MOUNT_POINT"; do { echo "\nAttempting to unmount $IMG_NAME from $MOUNT_POINT\n" ; } done
    echo "\nSuccessfully unmounted $IMG_NAME from $MOUNT_POINT\n"
    #e2fsck -yf ./extracted/$IMG_NAME.img
    #resize2fs -M ./extracted/$IMG_NAME.img
    main_menu
  }
  ascii_box "What partition would you like to unmount?"
  echo "\nCurrently mounted:\n" && set_global_vars
  echo "$MOUNTED_IMGS"
  echo -n "\nb) Main Menu\n\n>> " && read IMG_NAME
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" && unmount ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" && unmount ;;
    product*) MOUNT_POINT="./mounted/system/product" && unmount ;;
    [qb]) echo "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo "\nUnknown mount directory:\n$IMG_NAME" && unmount_img ;;
  esac
}

make_super() {
## Generate lpmake command from super & its sub-partitions
  dump_log && cat $LOG_FILE
  ascii_box "Saved lpmake command to: ./$LOG_FILE"
  echo -n "\nBuild new_super$HASHSTAMP.img ?\n[y/n]: "
  read make_new_super && echo ""
  case "$make_new_super" in
      y) ascii_box "Building new_super$HASHSTAMP.img..." && echo "" && silence mkdir ./out && eval $(sed -n '{134,148p}' $LOG_FILE) && echo "\nGenerated new super!" && main_menu ;;
      *) main_menu ;;
  esac
}

edit_boot_img() {
  boot_name="boot_a"
  silence mkdir -p ./extracted/boot/unpacked/ramdisk/

  extract() {
    img_path="/dev/block/by-name"
    extract_boot_img() { dd if=$img_path/$boot_name of=./extracted/boot/$boot_name.img bs=2048 status=progress && echo "\n$boot_name.img extracted from $img_path" ; }
    unpack_boot() { cd ./extracted/boot/unpacked/ && $magiskboot unpack -h ../$boot_name.img && cd ../../.. && echo "\n$boot_name.img unpacked.\n" ; }
    unpack_ramdisk() { cd ./extracted/boot/unpacked/ramdisk && $magiskboot cpio ../ramdisk.cpio extract && cd ../../../../ && echo "\n$boot_name.img Ramdisk unpacked.\n" ; }
    if [ -f "./extracted/boot/$boot_name.img" ]; then
      if [ -f "./extracted/boot/unpacked/header" ]; then
        if [ -f "./extracted/boot/unpacked/ramdisk/init" ]; then
          echo "$boot_name.img is Extracted and Ramdisk is unpacked @\n./extracted/boot/unpacked/ramdisk"
          prompt
        else
          unpack_ramdisk ; extract
        fi
      else
        unpack_boot ; $tree ./extracted/boot/ ; extract
      fi
    else
      extract_boot ; extract
    fi
  }
  repack() {
    cd ./extracted/boot/unpacked
    rm ramdisk.cpio && cd ramdisk
    find . | cpio -H newc -o > ../ramdisk.cpio
    cd .. && rm -r ramdisk
    $magiskboot repack ../$boot_name.img
    cd ../../..
    prompt
  }

  prompt() {
    echo "" && ascii_box "Boot image editor"
    echo -n "\n1] Extract ramdisk from boot.img\n2] Repack ramdisk into boot.img\n3] List contents of boot.img\n\nb] Main Menu\n\n>> " && read i && echo ""
    case "$i" in
        1) extract ;; 2) repack ;;
        3) ls -1 ./extracted/boot/ ./extracted/boot/unpacked/ ./extracted/boot/unpacked/ramdisk/ && prompt ;;
        b) echo "Heading back to Main Menu...\n" && main_menu ;;
        q) echo "Qutting..." && exit 0 ;;
        *) echo "Invalid choice, try again.\n" && prompt ;;
    esac
  }
  prompt
}

#Remove fileencryption from fstab
#./extracted/boot/unpacked/ramdisk/system/etc/recovery.fstab
#
#./mounted/system/vendor/etc/fstab.mt6765
#system /system ext4 rw wait,avb=vbmeta_system,logical,first_stage_mount,slotselect
#vendor /vendor ext4 rw wait,avb,logical,first_stage_mount,slotselect
#product /product ext4 rw wait,avb,logical,first_stage_mount,slotselect
#/dev/block/by-name/userdata /data ext4 noatime,nosuid,nodev,noauto_da_alloc,errors=panic,latemount,wait,check,reservedsize=128M,formattable,resize,,checkpoint=block,notencryptable

options_list() {
  func_acl() {
    ## Function access control
    input="$SCRIPT_NAME"
    deny="run_function detect_env detect_arch load_binaries \
      set_global_vars byte_calc bytes_to_mb bytes_to_gb bcalc apps \
      calculate_hash hash_changed refresh_sizes metadata parse \
      parse_tmp sanitize dump_variables init extract_size lpmake_cmd \
      function1 function2 function3 function4 function5 function6 \
      func_acl file_check options_list ascii_box ui_variables compare_hashes \
      find_hash_file find_log_file main_menu unmount mount dump_log \
      clean silence b2kb b2mb b2gb attributes extents name group group_name \
      image_group group_info sort_partitions print_partitions extract_boot_img \
      unpack_boot unpack_ramdisk repack_boot repack_ramdisk prompt"
    allow=""
    list_func=$(grep '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()' "$input" | sed 's/^[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
    for func in $list_func; do case "$deny" in *"$func"*) ;; *) allowed_func="$allowed_func$func " ;; esac done
    allowed_func=$(echo "$allowed_func" | sed 's/ $//') && echo "$allowed_func"
  }
  options=$($1) ; user_input="true"
  echo "Available options:"
  i=1
  for option in $options; do { echo "$i) $option" && i=$((i + 1)) ; } done
  echo -n "q) Quit\n\n>> "
  read -r func_name && echo ""
  [ "$func_name" = "q" ] && { echo "\nExiting..." && exit 0 ; }
  if [ "$func_name" -eq "$func_name" ] 2>/dev/null; then
    if [ "$func_name" -ge 1 ] && [ "$func_name" -le "$i" ]; then
      j=1
      for option in $options; do
      [ "$j" = "$func_name" ] && { func_name=$option && break ; }
      j=$((j + 1))
      done
    fi
  fi
  for option in $options; do [ "$func_name" = "$option" ] && { run_function "$func_name" && return ; } done
  echo "Invalid choice. Please try again.\n"
  user_input="false"
}

main_menu() {
  run_function() { func_name="$1" ; shift ; "$func_name" "$@" ; }
  ascii_box "Super Edit v0.2 - Main Menu"
  echo "Arch: $ARCH | $DISPLAY_HASH \n$STATUS"
  options_list func_acl
  [ $user_input = "false" ] && { main_menu ; } && return 0
}

file_check() {
  [ -f "./super.img" ] && { init_job=$(silence ls ./extracted/*.img && echo 1 || echo 2) ; extract_img ; return 0 ; }
    echo -n "\nNo super.img found within super-edit !\n\n1] Continue without using a super.img\n2] Pull or use super.img from device\nq] Quit super-edit\n\nChoice: " && read i
    echo"" && case "$i" in
        1) main_menu ;; 2) extract_img ;; q) exit 0 ;; esac
}

init() { detect_env; calculate_hash; silence metadata;
  [ "$start_option" = debug ] && { start_option="debug" ; dump_variables ; }
  file_check ; main_menu
}

## Start Options
start_option="$1"
## Run Super Edit
init

##
## ./super_edit.sh debug
##
## init -> detect_env -> calculate_hash ->
## silience metadata -> refresh_sizes -> dump_variables
## file_check -> extract_img -> main_menu
##
