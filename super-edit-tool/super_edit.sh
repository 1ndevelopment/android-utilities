#!/system/bin/sh

detect_env() {
  detect_arch() {
    BIN_DIR=$(pwd)/bin
    input=$(uname -m)
    case $input in
        arm) export ARCH=arm ;;
        aarch64) export ARCH=arm64 ;;
        x86) export ARCH=x86 ;;
        x86_64) export ARCH=x86_64 ;;
    esac
  }
  load_binaries() {
    BIN_EXEC="${BIN_DIR}/${ARCH}" ; input=$(uname -o)
    case $input in Android) export OS=android; BIN_EXEC="${BIN_DIR}/${ARCH}/${OS}" ;; esac
    for cmd in $(ls -1 "$BIN_EXEC"); do [ -x "$BIN_EXEC/$cmd" ] && { export $cmd=$BIN_EXEC/$cmd ; } done
  }
  set_global_vars() {
    MOUNTED_IMGS=$(sudo $busybox mount | grep /mounted/ | awk '{print $3}' | sed 's/.*\///')
    SCRIPT_NAME="$(basename "$0" | sed 's|.*/||')"
    LOG_FILE=".log" 
    TMP_FILE1=".tmp.1" ; TMP_FILE2=".tmp.2"
    silence() { "$@" >/dev/null 2>&1; }
  }
  detect_arch
  load_binaries
  set_global_vars
}

cleanup() {
  echo "\nCleaning up workspace...\n"
  clean() { i=$1 ; for o in $i; do [ -e "$o" ] && silence rm -rf "$o" ; done  ; }
  l=$(clean "./$LOG_FILE ./$HASH_FILE ./.tmp.* ./._")
  d=$(clean "./extracted ./mounted ./out")
  $d && $l && echo "\nCleanup completed." || echo "\nCleanup failed!"
  main_menu
}

bcalc() {
  i=$1 && s=$2
  2kb() { echo "scale=2; $1 / (1024)" | bc; }
  2mb() { echo "scale=2; $1 / (1024*1024)" | bc; }
  2gb() { echo "scale=2; $1 / (1024*1024*1024)" | bc; }
  case "$s" in *) r=$(2$s "$i"); echo "$r" ;; esac
}
b2kb() { bcalc "$1" kb; } && b2mb() { bcalc "$1" mb; } && b2gb() { bcalc "$1" gb; }

calculate_hash() {
  compare_hashes() {
    find_hash_file() { HASH_FILE=".previous_hash" ;
      [ -f "$HASH_FILE" ] && { previous_log=$(cat "$HASH_FILE") ; return 0 ; }
      echo "\nNo previous hash found. This might be the first run."
    }
    find_log_file() {
      [ ! -f "$LOG_FILE" ] && { echo "Generating hashes...\n" && touch $LOG_FILE; return 0; }
    }
    hash_changed() {
      DISPLAY_HASH=$(echo "Current hash: $current_hash | Previous hash: $previous_log")
    }
    calculate_hash() { current_hash=$(sha256sum "$LOG_FILE" | awk '{print substr($1, 1, 7)}')
      [ "$current_hash" != "$previous_log" ] && { hash_changed; return 0; }
      DISPLAY_HASH=$(echo "Current hash: $current_hash | Previous hash: $previous_log")
    }
    find_hash_file ; find_log_file ; calculate_hash
  }
  compare_hashes
  echo "$current_hash" > "$HASH_FILE"
  HASHSTAMP=$(echo _$current_hash)
}

metadata() {
  refresh_sizes() { silence rm -f $TMP_FILE1 $LOG_FILE
    find ./extracted -maxdepth 1 -name "*.img" -printf "%f %s\n" | sort -u >> $TMP_FILE1
    supertotal=$(stat -c '%s' ./super.img)
    imgtotal=$(find ./extracted -maxdepth 1 -name "*.img" -exec stat -c '%s' {} + | awk '{sum += $1} END {print sum}')
    echo -e "\nTotal Image Size: $imgtotal\nOverall Super Size: $supertotal\n" >> $TMP_FILE1
    $lpdump >> $TMP_FILE1
  }
  refresh_sizes

  ## functions that parse $TMP_FILE1 at certain coordinance for variable values
  size() { x="$1" && stat -c '%s' "$x" ; }
  parse() { x="$1"; y="$2" && echo "$x" | awk -v z="$y" '{print $z}' ; }
  sanitize() { grep -v '^[-]*$' | sed 's/^  *//' | paste -sd ' ' - | sed -e 's/:$//' -e 's/^(/ /' ; }
  attributes() { x="$1" && grep -e "Name: $x" -A2 "$TMP_FILE1" | sed -e '1,2d' -e 's/^  //' | awk '{print $2}' ; }
  extents() { x="$1" && grep -e "Name: $x" -A4 "$TMP_FILE1" | sed -e '1,4d' -e 's/^    //' ; }
  image_group() { x="$1" && grep -E "Partition table:" -A16 "$TMP_FILE1" | grep -e "Name: $x" -A4 ; }
  group_info() { x="$1" && grep -E "Group table:" -A16 "$TMP_FILE1" | grep -e "Name: $x" -A2 | sanitize ; }

  ## Calculate total size of all partitions inside super.img including super
  [ -f "./super.img" ] && {
    SUPER_PARTITION_NAME=$(grep "Partition name:" $TMP_FILE1 | sed -e 's/^  //' | awk '{print $3}')
    SUPER_SIZE=$(grep -e "Overall Super Size: " $TMP_FILE1 | awk '{print $4}')
    SUPER_TOTAL_MB=$(b2mb "$SUPER_SIZE") ; SUPER_TOTAL_GB=$(b2gb "$SUPER_SIZE")
    SUPER_LAYOUT=$(x="$1" && grep -e "super:" $TMP_FILE1 | sed 's/^super: //' | grep -e "$x")
    IMAGE_SIZE_TOTAL=$(grep -e "Total Image Size: " $TMP_FILE1 | awk '{print $4}')
    IMAGE_SIZE_TOTAL_MB=$(b2mb "$IMAGE_SIZE_TOTAL") ; IMAGE_SIZE_TOTAL_GB=$(b2gb "$IMAGE_SIZE_TOTAL")
    METADATA_VERSION=$(grep -e "Metadata version: " $TMP_FILE1 | awk '{print $3}')
    METADATA_SIZE=$(grep -e "Metadata size: " $TMP_FILE1 | awk '{print $3}')
    METADATA_MAX_SIZE=$(grep -e "Metadata max size: " $TMP_FILE1 | awk '{print $4}')
    METADATA_SLOT_COUNT=$(grep -e "Metadata slot count: " $TMP_FILE1 | awk '{print $4}')
    HEADER_FLAGS=$(grep -e "Header flags: " $TMP_FILE1 | awk '{print $3}')
    BLOCK_DEVICE_TABLE=$(grep -B1 -e "Block device table:" -A5 $TMP_FILE1)
  }

  [ -f "./extracted/product_a.img" ] && {
    PRODUCT_A_NAME="product_a"
    PRODUCT_A_SIZE=$(size "./extracted/product_a.img" || echo "0")
    PRODUCT_A_SIZE_MB=$(b2mb "$PRODUCT_A_SIZE") ; PRODUCT_A_SIZE_GB=$(b2gb "$PRODUCT_A_SIZE")
    PRODUCT_A_ATTRIBUTES=$(attributes "product_a")
    PRODUCT_A_EXTENTS=$(extents "product_a")
    PRODUCT_A_LAYOUT=$(echo "$SUPER_LAYOUT" | grep "product_a" || echo "0")
    PRODUCT_A_SECTOR_BEGIN=$(parse "$PRODUCT_A_LAYOUT" 1)
    PRODUCT_A_SECTOR_FINISH=$(parse "$PRODUCT_A_LAYOUT" 3 | sanitize)
    PRODUCT_A_SECTOR_SIZE=$(parse "$PRODUCT_A_LAYOUT" 5 | sanitize)
    PRODUCT_A_GROUP_NAME=$(image_group "product_a" | sed '1d;3,5d' | awk '{print $2}')

    PRODUCT_B_NAME="product_b"
    PRODUCT_B_SIZE=$(size "./extracted/product_b.img" || echo "0")
    PRODUCT_B_SIZE_MB=$(b2mb "$PRODUCT_B_SIZE") ; PRODUCT_B_SIZE_GB=$(b2gb "$PRODUCT_B_SIZE")
    PRODUCT_B_ATTRIBUTES=$(attributes "product_b")
    PRODUCT_B_EXTENTS=$(extents "product_b")
    PRODUCT_B_LAYOUT=$(echo "$SUPER_LAYOUT" | grep "product_b" || echo "0")
    PRODUCT_B_SECTOR_BEGIN=$(parse "$PRODUCT_B_LAYOUT" 1)
    PRODUCT_B_SECTOR_FINISH=$(parse "$PRODUCT_B_LAYOUT" 3 | sanitize)
    PRODUCT_B_SECTOR_SIZE=$(parse "$PRODUCT_B_LAYOUT" 5 | sanitize)
    PRODUCT_B_GROUP_NAME=$(image_group "product_b" | sed '1d;3,5d' | awk '{print $2}')
    PRODUCT_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $PRODUCT_B_SIZE" | bc)
    PRODUCT_TOTAL_MB=$(b2mb "$PRODUCT_TOTAL_SIZE") ; PRODUCT_TOTAL_GB=$(b2gb "$PRODUCT_TOTAL_SIZE")
  }

  [ -f "./extracted/system_a.img" ] && {
    SYSTEM_A_NAME="system_a"
    SYSTEM_A_SIZE=$(size "./extracted/system_a.img" || echo "0")
    SYSTEM_A_SIZE_MB=$(b2mb "$SYSTEM_A_SIZE") ; SYSTEM_A_SIZE_GB=$(b2gb "$SYSTEM_A_SIZE")
    SYSTEM_A_ATTRIBUTES=$(attributes "system_a")
    SYSTEM_A_EXTENTS=$(extents "system_a")
    SYSTEM_A_LAYOUT=$(echo "$SUPER_LAYOUT" | grep "system_a" || echo "0")
    SYSTEM_A_SECTOR_BEGIN=$(parse "$SYSTEM_A_LAYOUT" 1)
    SYSTEM_A_SECTOR_FINISH=$(parse "$SYSTEM_A_LAYOUT" 3 | sanitize)
    SYSTEM_A_SECTOR_SIZE=$(parse "$SYSTEM_A_LAYOUT" 5 | sanitize)
    SYSTEM_A_GROUP_NAME=$(image_group "system_a" | sed '1d;3,5d' | awk '{print $2}')

    SYSTEM_B_NAME="system_b"
    SYSTEM_B_SIZE=$(size "./extracted/system_b.img" || echo "0")
    SYSTEM_B_SIZE_MB=$(b2mb "$SYSTEM_B_SIZE") ; SYSTEM_B_SIZE_GB=$(b2gb "$SYSTEM_B_SIZE")
    SYSTEM_B_ATTRIBUTES=$(attributes "system_b")
    SYSTEM_B_EXTENTS=$(extents "system_b")
    SYSTEM_B_LAYOUT=$(echo "$SUPER_LAYOUT" | grep "system_b" || echo "0")
    SYSTEM_B_SECTOR_BEGIN=$(parse "$SYSTEM_B_LAYOUT" 1 )
    SYSTEM_B_SECTOR_FINISH=$(parse "$SYSTEM_B_LAYOUT" 3 | sanitize)
    SYSTEM_B_SECTOR_SIZE=$(parse "$SYSTEM_B_LAYOUT" 5 | sanitize)
    SYSTEM_B_GROUP_NAME=$(image_group "system_b" | sed '1d;3,5d' | awk '{print $2}')
    SYSTEM_TOTAL_SIZE=$(echo "$SYSTEM_A_SIZE + $SYSTEM_B_SIZE" | bc)
    SYSTEM_TOTAL_MB=$(b2mb "$SYSTEM_TOTAL_SIZE") ; SYSTEM_TOTAL_GB=$(b2gb "$SYSTEM_TOTAL_SIZE")
  }

  [ -f "./extracted/vendor_a.img" ] && {
    VENDOR_A_NAME="vendor_a"
    VENDOR_A_SIZE=$(size "./extracted/vendor_a.img" || echo "0")
    VENDOR_A_SIZE_MB=$(b2mb "$VENDOR_A_SIZE") ; VENDOR_A_SIZE_GB=$(b2gb "$VENDOR_A_SIZE")
    VENDOR_A_ATTRIBUTES=$(attributes "vendor_a")
    VENDOR_A_EXTENTS=$(extents "vendor_a")
    VENDOR_A_LAYOUT=$(echo "$SUPER_LAYOUT" | grep "vendor_a" || echo "0")
    VENDOR_A_SECTOR_BEGIN=$(parse "$VENDOR_A_LAYOUT" 1 )
    VENDOR_A_SECTOR_FINISH=$(parse "$VENDOR_A_LAYOUT" 3 | sanitize)
    VENDOR_A_SECTOR_SIZE=$(parse "$VENDOR_A_LAYOUT" 5 | sanitize)
    VENDOR_A_GROUP_NAME=$(image_group "vendor_a" | sed '1d;3,5d' | awk '{print $2}')

    VENDOR_B_NAME="vendor_b"
    VENDOR_B_SIZE=$(size "./extracted/vendor_b.img" || echo "0")
    VENDOR_B_SIZE_MB=$(b2mb "$VENDOR_B_SIZE") ; VENDOR_B_SIZE_GB=$(b2gb "$VENDOR_B_SIZE")
    VENDOR_B_ATTRIBUTES=$(attributes "vendor_b")
    VENDOR_B_EXTENTS=$(extents "vendor_b" || echo "0")
    VENDOR_B_LAYOUT=$(echo "$SUPER_LAYOUT" | grep "vendor_b" || echo "0")
    VENDOR_B_SECTOR_BEGIN=$(parse "$VENDOR_B_LAYOUT" 1)
    VENDOR_B_SECTOR_FINISH=$(parse "$VENDOR_B_LAYOUT" 3 | sanitize)
    VENDOR_B_SECTOR_SIZE=$(parse "$VENDOR_B_LAYOUT" 5 | sanitize)
    VENDOR_B_GROUP_NAME=$(image_group "vendor_b" | sed '1d;3,5d' | awk '{print $2}')
    VENDOR_TOTAL_SIZE=$(echo "$VENDOR_A_SIZE + $VENDOR_B_SIZE" | bc)
    VENDOR_TOTAL_MB=$(b2mb "$VENDOR_TOTAL_SIZE") ; VENDOR_TOTAL_GB=$(b2gb "$VENDOR_TOTAL_SIZE")
  }

  [ -f "./extracted/product_a.img" ] && [ -f "./extracted/system_a.img" ] && [ -f "./extracted/vendor_a.img" ] && {
    MAIN_A_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $SYSTEM_A_SIZE + $VENDOR_A_SIZE" | bc || echo "0")
    MAIN_A_TOTAL_MB=$(b2mb "$MAIN_A_TOTAL_SIZE") ; MAIN_A_TOTAL_GB=$(b2gb "$MAIN_A_TOTAL_SIZE")
    MAIN_A_MAX_SIZE=$(group_info "main_a" | awk '{print $5}') ; MAIN_A_MAX_MB=$(b2mb "$MAIN_A_MAX_SIZE")
    MAIN_A_MAX_GB=$(b2gb "$MAIN_A_MAX_SIZE") ; MAIN_A_FLAGS=$(group_info "main_a" | awk '{print $8}')

    MAIN_B_TOTAL_SIZE=$(echo "$PRODUCT_B_SIZE + $SYSTEM_B_SIZE + $VENDOR_B_SIZE" | bc || echo "0")
    MAIN_B_TOTAL_MB=$(b2mb "$MAIN_B_TOTAL_SIZE") ; MAIN_B_TOTAL_GB=$(b2gb "$MAIN_B_TOTAL_SIZE")
    MAIN_B_MAX_SIZE=$(group_info "main_b" | awk '{print $5}') ; MAIN_B_MAX_MB=$(b2mb "$MAIN_B_MAX_SIZE")
    MAIN_B_MAX_GB=$(b2gb "$MAIN_B_MAX_SIZE") MAIN_B_FLAGS=$(group_info "main_b" | awk '{print $8}')
  }
}

dump_log() {

  silence metadata
  silence rm -f $LOG_FILE

{
cat << EOF
------------------------
 Super Partition Table:
------------------------

* Name: $PRODUCT_A_NAME
   Group: $PRODUCT_A_GROUP_NAME
     Attributes: $PRODUCT_A_ATTRIBUTES
      Size: $PRODUCT_A_SIZE B
            $PRODUCT_A_SIZE_MB MB
            $PRODUCT_A_SIZE_GB GB

      Extents:
  $PRODUCT_A_EXTENTS

* Name: $PRODUCT_B_NAME
   Group: $PRODUCT_B_GROUP_NAME
     Attributes: $PRODUCT_B_ATTRIBUTES
      Size: $PRODUCT_B_SIZE B
            $PRODUCT_B_SIZE_MB MB
            $PRODUCT_B_SIZE_GB GB

      Extents:
  $PRODUCT_B_EXTENTS

* Product Total: $PRODUCT_TOTAL_SIZE B
                 $PRODUCT_TOTAL_MB MB
                 $PRODUCT_TOTAL_GB GB

* Name: $SYSTEM_A_NAME
   Group: $SYSTEM_A_GROUP_NAME
     Attributes: $SYSTEM_A_ATTRIBUTES
      Size: $SYSTEM_A_SIZE B
            $SYSTEM_A_SIZE_MB MB
            $SYSTEM_A_SIZE_GB GB

      Extents:
  $SYSTEM_A_EXTENTS

* Name: $SYSTEM_B_NAME
   Group: $SYSTEM_B_GROUP_NAME
     Attributes: $SYSTEM_B_ATTRIBUTES
      Size: $SYSTEM_B_SIZE B
            $SYSTEM_B_SIZE_MB MB
            $SYSTEM_B_SIZE_GB GB

      Extents:
  $SYSTEM_B_EXTENTS

* System Total: $SYSTEM_TOTAL_SIZE B
                $SYSTEM_TOTAL_MB MB
                $SYSTEM_TOTAL_GB GB

* Name: $VENDOR_A_NAME
   Group: $VENDOR_A_GROUP_NAME
     Attributes: $VENDOR_A_ATTRIBUTES
      Size: $VENDOR_A_SIZE B
            $VENDOR_A_SIZE_MB MB
            $VENDOR_A_SIZE_GB GB

      Extents:
  $VENDOR_A_EXTENTS

* Name: $VENDOR_B_NAME
   Group: $VENDOR_B_GROUP_NAME
     Attributes: $VENDOR_B_ATTRIBUTES
      Size: $VENDOR_B_SIZE B
            $VENDOR_B_SIZE_MB MB
            $VENDOR_B_SIZE_GB GB

      Extents:
  $VENDOR_B_EXTENTS

* Vendor Total: $VENDOR_TOTAL_SIZE B
                $VENDOR_TOTAL_MB MB
                $VENDOR_TOTAL_GB GB

------------------------
Group Table Information:
------------------------

*  Name: $GROUP_DEFAULT_NAME
     Maximum size: $GROUP_DEFAULT_MAX_SIZE B
     Flags: $GROUP_DEFAULT_FLAGS

*  Name: main_a
     Current size: $MAIN_A_TOTAL_SIZE B
     Maximum size: $MAIN_A_MAX_SIZE B
     Flags: $MAIN_A_FLAGS

*  Name: main_b
     Current size: $MAIN_B_TOTAL_SIZE B
     Maximum size: $MAIN_B_MAX_SIZE B
     Flags: $MAIN_B_FLAGS

------------------------
Super Overview:
------------------------

$METADATA_INFO

$BLOCK_DEVICE_TABLE

$SUPER_LAYOUT

$SUPER_PARTITION_NAME:        $SUPER_SIZE B $SUPER_TOTAL_MB MB $SUPER_TOTAL_GB GB

Image sizes:  $IMAGE_SIZE_TOTAL B $IMAGE_SIZE_TOTAL_MB MB $IMAGE_SIZE_TOTAL_GB GB

main_a:       $MAIN_A_TOTAL_SIZE B $MAIN_A_TOTAL_MB MB $MAIN_A_TOTAL_GB GB
|_$PRODUCT_A_NAME:  $PRODUCT_A_SIZE B $PRODUCT_A_SIZE_MB MB $PRODUCT_A_SIZE_GB GB
|_$SYSTEM_A_NAME:   $SYSTEM_A_SIZE B $SYSTEM_A_SIZE_MB MB $SYSTEM_A_SIZE_GB GB
|_$VENDOR_A_NAME:   $VENDOR_A_SIZE B $VENDOR_A_SIZE_MB MB $VENDOR_A_SIZE_GB GB

main_b:                $MAIN_B_TOTAL_SIZE B       $MAIN_B_TOTAL_MB MB      $MAIN_B_TOTAL_GB GB
|_$PRODUCT_B_NAME:           $PRODUCT_B_SIZE B       $PRODUCT_B_SIZE_MB MB    $PRODUCT_B_SIZE_GB GB
|_$SYSTEM_B_NAME:            $SYSTEM_B_SIZE B       $SYSTEM_B_SIZE_MB MB    $SYSTEM_B_SIZE_GB GB
|_$VENDOR_B_NAME:            $VENDOR_B_SIZE B       $VENDOR_B_SIZE_MB MB    $VENDOR_B_SIZE_GB GB

------------------------
lpmake command:
------------------------

lpmake \
--metadata-size $METADATA_MAX_SIZE \
--super-name=$SUPER_PARTITION_NAME \
--device-size=$SUPER_SIZE \
--metadata-slots=$METADATA_SLOT_COUNT \
--group=main_a:$MAIN_A_MAX_SIZE \
--group=main_b:$MAIN_B_MAX_SIZE \
--image=$PRODUCT_A_NAME=./extracted/$PRODUCT_A_NAME.img \
--partition=$PRODUCT_A_NAME:$PRODUCT_A_ATTRIBUTES:$PRODUCT_A_SIZE:$MAIN_A_NAME \
--image=$PRODUCT_B_NAME=./extracted/$PRODUCT_B_NAME.img \
--partition=$PRODUCT_B_NAME:$PRODUCT_B_ATTRIBUTES:$PRODUCT_B_SIZE:$MAIN_B_NAME \
--image=$SYSTEM_A_NAME=./extracted/$SYSTEM_A_NAME.img \
--partition=$SYSTEM_A_NAME:$SYSTEM_A_ATTRIBUTES:$SYSTEM_A_SIZE:$MAIN_A_NAME \
--image=$SYSTEM_B_NAME=./extracted/$SYSTEM_B_NAME.img \
--partition=$SYSTEM_B_NAME:$SYSTEM_B_ATTRIBUTES:$SYSTEM_B_SIZE:$MAIN_B_NAME \
--image=$VENDOR_A_NAME=./extracted/$VENDOR_A_NAME.img \
--partition=$VENDOR_A_NAME:$VENDOR_A_ATTRIBUTES:$VENDOR_A_SIZE:$MAIN_A_NAME \
--image=$VENDOR_B_NAME=./extracted/$VENDOR_B_NAME.img \
--partition=$VENDOR_B_NAME:$VENDOR_B_ATTRIBUTES:$VENDOR_B_SIZE:$MAIN_B_NAME \
--virtual-ab \
--sparse \
--output ./out/new_super$HASHSTAMP.img

EOF
} >> $LOG_FILE
  return 0
}

dump_variables() {
  dump_log && echo "$(ascii_box "Useful Variables")\n" >> $LOG_FILE
  sed -n 's/[^ ]*=[^ ]*/\n&\n/gp' $SCRIPT_NAME | grep '=' | \
  awk -F'=' '{gsub(/[^A-Z_]/, "", $1); if ($1 != "") print $1}' | \
  sed 's/\($F\|NR\)//g' | sort -u | head -n -1 | \
  sed -e '3d' -e '/^F$/d' -e '/^IFS/d' -e '/^LP/d' -e '/^L/d' >> $TMP_FILE2
  while IFS= read -r var_name; do
    [ -n "$var_name" ] && [ "${var_name#\#}" = "$var_name" ] && { var_value=$(eval echo "\$$var_name") ; output+="$var_name=$var_value\n" ; }
  done < $TMP_FILE2
  [ -n "$output" ] && { echo -e "$output" | grep -v "^_=" >> $LOG_FILE ; }
  rm -f $TMP_FILE2 && cat $LOG_FILE
  return 0
}

extract_img() {
## Extract super or sub-partitions of super
  if [ -f "./super.img" ]; then
      STATUS="\nInitialized.\n\nFound super.img."
      if silence ls ./extracted/*.img ; then
          STATUS+="\nImages are located in ./extracted \n"
          [ "$init_job" -eq 1 ] && { init_job=0 && main_menu ; }
      else
          STATUS+="\nNo partitions have been extracted.\n"
          [ "$init_job" -eq 2 ] && { init_job=0 && main_menu ; }
      fi
      echo -n "Extract partitions from super.img ?\n[y/n]: " && read input && echo ""
      case "$input" in
          y)
             echo "\nExtracting partitons from super.img...\n"
             $imjtool ./super.img extract
             init_job=1 && extract_img ;;
          n)
             init_job=2 ; main_menu ;;
          *)
             main_menu ;;
      esac
  else
      echo -n "\nPull super.img from /dev/block/by-name/super ?\n[y/n]: " && read input && echo ""
      case "$input" in
          y)
             echo "Dumping /dev/block/by-name/super to ./super.img ..."
             dd if=/dev/block/by-name/super of=./super.img bs=4096 status=progress
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
  echo "\nMountable partitions:\n"
  ls -1 ./extracted | sed -e 's/\.img$//'
  echo -n "\nb) Main Menu\n\n>> "
  read IMG_NAME && echo ""
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
  dump_log
  cat $LOG_FILE
  ascii_box "Saved lpmake command to: ./$LOG_FILE"
  echo -n "\nBuild new_super$HASHSTAMP.img ?\n[y/n]: "
  read make_new_super && echo ""
  case "$make_new_super" in
      [Yy])
         ascii_box "Building new_super$HASHSTAMP.img..."
         silence mkdir ./out && eval $(sed -n '{134,148p}' $LOG_FILE)
         echo "\nGenerated new super!" && main_menu ;;
      *) main_menu ;;
  esac
}

#Remove fileencryption from fstab
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
      image_group group_info"
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

ascii_box() {
  text_input="$1" ; max_width=$((COLUMNS - 8)) ; box_width=$max_width
  border=$(printf '%*s' "$((box_width-2))" | tr ' ' '=')
  print_border="x${border}x" ; content_width=$((box_width - 6))
  # Print the top of the box
  echo "$print_border\n|$(printf '%*s' "$((box_width-2))")|" ; line=""
  for words in $text_input; do
    if [ $((${#line} + ${#words} + 1)) -le $content_width ]; then
      [ -n "$line" ] && line+=" " ; line+="$words"
    else
      # Print the current line
      padding=$(( (box_width - ${#line} - 2) / 2 ))
      printf "|%*s%s%*s|\n" $padding "" "$line" $((box_width - padding - ${#line} - 2)) ""
      line="$words"
    fi
  done
  # Print the last line if there's any content left
  [ -n "$line" ] && { padding=$(( (box_width - ${#line} - 2) / 2 )) ; printf "|%*s%s%*s|\n" $padding "" "$line" $((box_width - padding - ${#line} - 2)) "" ; }
  echo "|$(printf '%*s' "$((box_width-2))")|\n$print_border"
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
   echo "\nNo super.img found within super-edit !\n\n1] Continue without using a super.img\n2] Pull or use super.img from device\nq] Quit super-edit\n"
    echo -n "Choice: "
    read input; case "$input" in
        1) main_menu ;; 2) extract_img ;; q) exit 0 ;; esac
}

init() { detect_env; calculate_hash; silence metadata;
  debug_mode() { STATUS="\nInitialized in Debug Mode.\n" ; dump_variables ; file_check ; main_menu ; }
  [ "$start_option" = debug ] && { debug_mode ; return 0 ; }
  STATUS="\nInitialized.\n" && file_check
}

run() {
  init
  main_menu
}

## Start Options
start_option=$1
## Start Super Edit
run
