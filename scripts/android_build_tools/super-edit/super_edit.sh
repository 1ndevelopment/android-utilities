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
    BIN_EXEC="${BIN_DIR}/${ARCH}"
    input=$(uname -o)
    case $input in
        Android) export OS=android; BIN_EXEC="${BIN_DIR}/${ARCH}/${OS}" ;;
    esac
    for cmd in $(ls -1 "$BIN_EXEC"); do
        if [ -x "$BIN_EXEC/$cmd" ]; then
            export $cmd=$BIN_EXEC/$cmd
        fi
    done
  }
  set_global_vars() {
    SCRIPT_NAME="$(basename "$0" | sed 's|.*/||')"
    TMP_FILE1=".tmp.1" ; TMP_FILE2=".tmp.2"
    silence() { "$@" >/dev/null 2>&1; }
  }
  detect_arch
  load_binaries
  set_global_vars
}

cleanup() {
  echo "\nCleaning up workspace...\n"
  clean() { i=$1;
    for o in $i; do [ -e "$o" ] && silence rm -rf "$o"; done }
  l=$(clean "./$LOG_FILE ./$HASH_FILE ./.tmp.* ./._")
  d=$(clean "./extracted ./mounted ./out")
  $d && $l
  echo "\nCleanup completed."
  main_menu
}

byte_calc() {
  input=$1 && command=$2
  bytes_to_mb() { echo "scale=2; $1 / (1024*1024)" | bc; }
  bytes_to_gb() { echo "scale=2; $1 / (1024*1024*1024)" | bc; }
  case "$command" in
      mb) mb_result=$(bytes_to_mb "$input"); echo "$mb_result" ;;
      gb) gb_result=$(bytes_to_gb "$input"); echo "$gb_result" ;;
      *) echo "Unknown command. Use mb or gb."; return 1 ;;
  esac
}
b2mb() { byte_calc "$1" mb; } && b2gb() { byte_calc "$1" gb; }

calculate_hash() {
  compare_hashes() {
    find_hash_file() { HASH_FILE=".previous_hash" ;
      [ -f "$HASH_FILE" ] && { previous_log=$(cat "$HASH_FILE"); return 0; }
      echo "\nNo previous hash found. This might be the first run."
    }
    find_log_file() { LOG_FILE=".log" ;
      [ ! -f "$LOG_FILE" ] && { echo "Generating $LOG_FILE..." && touch $LOG_FILE; return 0; }
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
  refresh_sizes() {
    silence rm -f $TMP_FILE1 $LOG_FILE
    find ./extracted -maxdepth 1 -name "*.img" -printf "%f %s\n" | sort -u >> $TMP_FILE1
    supertotal=$(stat -c '%s' ./super.img)
    imgtotal=$(find ./extracted -maxdepth 1 -name "*.img" -exec stat -c '%s' {} + | awk '{sum += $1} END {print sum}')
    echo -e "\nTotal Image Size: $imgtotal\nOverall Super Size: $supertotal\n" >> $TMP_FILE1
    $lpdump >> $TMP_FILE1
  }
  refresh_sizes

  parse() { x="$1"; y="$2" && echo "$x" | awk -v z="$y" '{print $z}' ; }
  parse_tmp() { x="${1:-1}"; y="${2:-1}" && head -n $x < $TMP_FILE1 | tail -n $y ; }

  sanitize() { grep -v '^[-]*$' | sed 's/^  *//' | paste -sd ' ' - | sed -e 's/:$//' -e 's/^(/ /' ; }

  ## parses $LOG_FILE at certain coordinance for variable values
  SUPER_PARTITION_NAME=$(parse "$(parse_tmp 61)" 3)

  PRODUCT_A_ATTRIBUTES=$(parse "$(parse_tmp 20)" 2) ; PRODUCT_A_EXTENTS=$(parse_tmp 22) ;
  PRODUCT_A_LAYOUT=$(parse_tmp 54 | sanitize | sed 's/^super: //')
  PRODUCT_A_SECTOR_BEGIN=$(parse "$PRODUCT_A_LAYOUT" 1)
  PRODUCT_A_SECTOR_FINISH=$(parse "$PRODUCT_A_LAYOUT" 3 | sanitize)
  PRODUCT_A_SECTOR_SIZE=$(parse "$PRODUCT_A_LAYOUT" 5 | sanitize)

  PRODUCT_B_ATTRIBUTES=$(parse "$(parse_tmp 26)" 2) ; PRODUCT_B_EXTENTS="" ;
  PRODUCT_B_LAYOUT="" ; PRODUCT_B_SECTOR_BEGIN="" ; PRODUCT_B_SECTOR_FINISH="" ;
  PRODUCT_B_SECTOR_SIZE=""

  SYSTEM_A_ATTRIBUTES=$(parse "$(parse_tmp 31)" 2) ; SYSTEM_A_EXTENTS=$(parse_tmp 33) ;
  SYSTEM_A_LAYOUT=$(parse_tmp 55 | sanitize | sed 's/^super: //')
  SYSTEM_A_SECTOR_BEGIN=$(parse "$SYSTEM_A_LAYOUT" 1)
  SYSTEM_A_SECTOR_FINISH=$(parse "$SYSTEM_A_LAYOUT" 3 | sanitize)
  SYSTEM_A_SECTOR_SIZE=$(parse "$SYSTEM_A_LAYOUT" 5 | sanitize)

  SYSTEM_B_ATTRIBUTES=$(parse "$(parse_tmp 37)" 2) ; SYSTEM_B_EXTENTS=$(parse_tmp 39) ;
  SYSTEM_B_LAYOUT=$(parse_tmp 56 | sanitize | sed 's/^super: //')
  SYSTEM_B_SECTOR_BEGIN=$(parse "$SYSTEM_B_LAYOUT" 1 )
  SYSTEM_B_SECTOR_FINISH=$(parse "$SYSTEM_B_LAYOUT" 3 | sanitize)
  SYSTEM_B_SECTOR_SIZE=$(parse "$SYSTEM_B_LAYOUT" 5 | sanitize)

  VENDOR_A_ATTRIBUTES=$(parse "$(parse_tmp 43)" 2) ; VENDOR_A_EXTENTS=$(parse_tmp 45) ;
  VENDOR_A_LAYOUT=$(parse_tmp 57 | sanitize | sed 's/^super: //')
  VENDOR_A_SECTOR_BEGIN=$(parse "$VENDOR_A_LAYOUT" 1 )
  VENDOR_A_SECTOR_FINISH=$(parse "$VENDOR_A_LAYOUT" 3 | sanitize)
  VENDOR_A_SECTOR_SIZE=$(parse "$VENDOR_A_LAYOUT" 5 | sanitize)

  VENDOR_B_ATTRIBUTES=$(parse "$(parse_tmp 49)" 2) ; VENDOR_B_EXTENTS="" ;
  VENDOR_B_LAYOUT="" ; VENDOR_B_SECTOR_BEGIN="" ; VENDOR_B_SECTOR_FINISH="" ;
  VENDOR_B_SECTOR_SIZE=""

  METADATA_INFO=$(parse_tmp 15 5)
  SUPER_LAYOUT=$(parse_tmp 57 4 | sanitize)
  PARTITION_TABLE=$(parse_tmp 51 36 | sanitize)
  BLOCK_DEVICE_TABLE=$(parse_tmp 64 4 | sanitize)
  SUPER_GROUP_TABLE=$(parse_tmp 78 11 | sanitize)

#Extract values from recently generated .tmp file ($TMP_FILE1)
  while read -r line; do
      case "$line" in
          "Overall Super Size:"*) export SUPER_SIZE=$(parse "$line" 4) ;;
          "Total Image Size:"*) export IMAGE_SIZE_TOTAL=$(parse "$line" 4) ;;
          "Metadata version:"*) export METADATA_VERSION=$(parse "$line" 3) ;;
          "Metadata size:"*) export METADATA_SIZE=$(parse "$line" 3) ;;
          "Metadata max size:"*) export METADATA_MAX_SIZE=$(parse "$line" 4) ;;
          "Metadata slot count:"*) export METADATA_SLOT_COUNT=$(parse "$line" 4) ;;
          "Header flags:"*) export HEADER_FLAGS=$(parse "$line" 3) ;;
          "Name: product_a"*) export PRODUCT_A=$(parse "$line" 2) ;;
          product_a.img*) export PRODUCT_A_SIZE=$(parse "$line" 2) ;;
          "Name: product_b"*) export PRODUCT_B=$(parse "$line" 2) ;;
          product_b.img*) export PRODUCT_B_SIZE=$(parse "$line" 2) ;;
          "Name: system_a"*) export SYSTEM_A=$(parse "$line" 2) ;;
          system_a.img*) export SYSTEM_A_SIZE=$(parse "$line" 2) ;;
          "Name: system_b"*) export SYSTEM_B=$(parse "$line" 2) ;;
          system_b.img*) export SYSTEM_B_SIZE=$(parse "$line" 2) ;;
          "Name: vendor_a"*) export VENDOR_A=$(parse "$line" 2) ;;
          vendor_a.img*) export VENDOR_A_SIZE=$(parse "$line" 2) ;;
          "Name: vendor_b"*) export VENDOR_B=$(parse "$line" 2) ;;
          vendor_b.img*) export VENDOR_B_SIZE=$(parse "$line" 2) ;;
          "Group table:"*) ;;
          "Name: "*)
              current_group=$(parse "$line" 2)
              case "$current_group" in
                  "default") GROUP_DEFAULT_NAME=$current_group ;;
                  "main_a") GROUP_MAIN_A_NAME=$current_group ;;
                  "main_b") GROUP_MAIN_B_NAME=$current_group ;;
              esac
              ;;
          "Maximum size: "*)
              size=$(parse "$line" 3)
              case "$current_group" in
                  "default") GROUP_DEFAULT_MAX_SIZE=$size ;;
                  "main_a") GROUP_MAIN_A_MAX_SIZE=$size ;;
                  "main_b") GROUP_MAIN_B_MAX_SIZE=$size ;;
              esac
              ;;
          "Flags: "*)
              flags=$(parse "$line" 2)
              case "$current_group" in
                  "default") GROUP_DEFAULT_FLAGS=$flags ;;
                  "main_a") GROUP_MAIN_A_FLAGS=$flags ;;
                  "main_b") GROUP_MAIN_B_FLAGS=$flags ;;
              esac
              ;;
      esac
  done < $TMP_FILE1
  ## Calculate total size of all partitions inside super.img including super
  SUPER_TOTAL_MB=$(b2mb "$SUPER_SIZE") ; SUPER_TOTAL_GB=$(b2gb "$SUPER_SIZE")
  IMAGE_SIZE_TOTAL_MB=$(b2mb "$IMAGE_SIZE_TOTAL") ; IMAGE_SIZE_TOTAL_GB=$(b2gb "$IMAGE_SIZE_TOTAL")

  PRODUCT_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $PRODUCT_B_SIZE" | bc)
  PRODUCT_TOTAL_MB=$(b2mb "$PRODUCT_TOTAL_SIZE") ; PRODUCT_TOTAL_GB=$(b2gb "$PRODUCT_TOTAL_SIZE")
  PRODUCT_A_SIZE_MB=$(b2mb "$PRODUCT_A_SIZE") ; PRODUCT_A_SIZE_GB=$(b2gb "$PRODUCT_A_SIZE")
  PRODUCT_B_SIZE_MB=$(b2mb "$PRODUCT_B_SIZE") ; PRODUCT_B_SIZE_GB=$(b2gb "$PRODUCT_B_SIZE")
  SYSTEM_TOTAL_SIZE=$(echo "$SYSTEM_A_SIZE + $SYSTEM_B_SIZE" | bc)
  SYSTEM_TOTAL_MB=$(b2mb "$SYSTEM_TOTAL_SIZE") ; SYSTEM_TOTAL_GB=$(b2gb "$SYSTEM_TOTAL_SIZE")
  SYSTEM_A_SIZE_MB=$(b2mb "$SYSTEM_A_SIZE") ; SYSTEM_A_SIZE_GB=$(b2gb "$SYSTEM_A_SIZE")
  SYSTEM_B_SIZE_MB=$(b2mb "$SYSTEM_B_SIZE") ; SYSTEM_B_SIZE_GB=$(b2gb "$SYSTEM_B_SIZE")
  VENDOR_TOTAL_SIZE=$(echo "$VENDOR_A_SIZE + $VENDOR_B_SIZE" | bc)
  VENDOR_TOTAL_MB=$(b2mb "$VENDOR_TOTAL_SIZE") ; VENDOR_TOTAL_GB=$(b2gb "$VENDOR_TOTAL_SIZE")
  VENDOR_A_SIZE_MB=$(b2mb "$VENDOR_A_SIZE") ; VENDOR_A_SIZE_GB=$(b2gb "$VENDOR_A_SIZE")
  VENDOR_B_SIZE_MB=$(b2mb "$VENDOR_B_SIZE") ; VENDOR_B_SIZE_GB=$(b2gb "$VENDOR_B_SIZE")

  MAIN_A_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $SYSTEM_A_SIZE + $VENDOR_A_SIZE" | bc)
  MAIN_A_TOTAL_MB=$(b2mb "$MAIN_A_TOTAL_SIZE") ; MAIN_A_TOTAL_GB=$(b2gb "$MAIN_A_TOTAL_SIZE")
  MAIN_B_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $SYSTEM_A_SIZE + $VENDOR_A_SIZE" | bc)
  MAIN_B_TOTAL_MB=$(b2mb "$MAIN_B_TOTAL_SIZE") ; MAIN_B_TOTAL_GB=$(b2gb "$MAIN_B_TOTAL_SIZE")
}

dump_log() {

  metadata
  silence rm -f $LOG_FILE

{
cat << EOF

x-------------------------------------------x
                    Super
               Partition Table:
x-------------------------------------------x

* Name: $PRODUCT_A
   Group: $GROUP_MAIN_A_NAME
     Attributes: $PRODUCT_A_ATTRIBUTES
      Size: $PRODUCT_A_SIZE B
            $PRODUCT_A_SIZE_MB MB
            $PRODUCT_A_SIZE_GB GB

      Extents:
  $PRODUCT_A_EXTENTS

* Name: $PRODUCT_B
   Group: $GROUP_MAIN_B_NAME
     Attributes: $PRODUCT_B_ATTRIBUTES
      Size: $PRODUCT_B_SIZE B
            $PRODUCT_B_SIZE_MB MB
            $PRODUCT_B_SIZE_GB GB

      Extents:
  $PRODUCT_B_EXTENTS

* Product Total: $PRODUCT_TOTAL_SIZE B
                 $PRODUCT_TOTAL_MB MB
                 $PRODUCT_TOTAL_GB GB

* Name: $SYSTEM_A
   Group: $GROUP_MAIN_A_NAME
     Attributes: $SYSTEM_A_ATTRIBUTES
      Size: $SYSTEM_A_SIZE B
            $SYSTEM_A_SIZE_MB MB
            $SYSTEM_A_SIZE_GB GB

      Extents:
  $SYSTEM_A_EXTENTS

* Name: $SYSTEM_B
   Group: $GROUP_MAIN_B_NAME
     Attributes: $SYSTEM_B_ATTRIBUTES
      Size: $SYSTEM_B_SIZE B
            $SYSTEM_B_SIZE_MB MB
            $SYSTEM_B_SIZE_GB GB

      Extents:
  $SYSTEM_B_EXTENTS

* System Total: $SYSTEM_TOTAL_SIZE B
                $SYSTEM_TOTAL_MB MB
                $SYSTEM_TOTAL_GB GB

* Name: $VENDOR_A
   Group: $GROUP_MAIN_A_NAME
     Attributes: $VENDOR_A_ATTRIBUTES
      Size: $VENDOR_A_SIZE B
            $VENDOR_A_SIZE_MB MB
            $VENDOR_A_SIZE_GB GB

      Extents:
  $VENDOR_A_EXTENTS

* Name: $VENDOR_B
   Group: $GROUP_MAIN_B_NAME
     Attributes: $VENDOR_B_ATTRIBUTES
      Size: $VENDOR_B_SIZE B
            $VENDOR_B_SIZE_MB MB
            $VENDOR_B_SIZE_GB GB

      Extents:
  $VENDOR_B_EXTENTS

* Vendor Total: $VENDOR_TOTAL_SIZE B
                $VENDOR_TOTAL_MB MB
                $VENDOR_TOTAL_GB GB

x-------------------------------------------x
             Group Table Info
x-------------------------------------------x

*  Name: $GROUP_DEFAULT_NAME
     Maximum size: $GROUP_DEFAULT_MAX_SIZE B
     Flags: $GROUP_DEFAULT_FLAGS
*  Name: $GROUP_MAIN_A_NAME
     Current size: $MAIN_A_TOTAL_SIZE B
     Maximum size: $GROUP_MAIN_A_MAX_SIZE B
     Flags: $GROUP_MAIN_A_FLAGS
*  Name: $GROUP_MAIN_B_NAME
     Current size: $MAIN_B_TOTAL_SIZE B
     Maximum size: $GROUP_MAIN_B_MAX_SIZE B
     Flags: $GROUP_MAIN_B_FLAGS

x-------------------------------------------x
               Super Overview
x-------------------------------------------x

$METADATA_INFO

$BLOCK_DEVICE_TABLE

$SUPER_LAYOUT

$SUPER_PARTITION_NAME:        $SUPER_SIZE B $SUPER_TOTAL_MB MB $SUPER_TOTAL_GB GB

Image sizes:  $IMAGE_SIZE_TOTAL B $IMAGE_SIZE_TOTAL_MB MB $IMAGE_SIZE_TOTAL_GB GB

$GROUP_MAIN_A_NAME:       $MAIN_A_TOTAL_SIZE B $MAIN_A_TOTAL_MB MB $MAIN_A_TOTAL_GB GB
|_$PRODUCT_A:  $PRODUCT_A_SIZE B $PRODUCT_A_SIZE_MB MB $PRODUCT_A_SIZE_GB GB
|_$SYSTEM_A:   $SYSTEM_A_SIZE B $SYSTEM_A_SIZE_MB MB $SYSTEM_A_SIZE_GB GB
|_$VENDOR_A:    $VENDOR_A_SIZE B  $VENDOR_A_SIZE_MB MB  $VENDOR_A_SIZE_GB GB

$GROUP_MAIN_B_NAME:       $MAIN_B_TOTAL_SIZE B $MAIN_B_TOTAL_MB MB $MAIN_B_TOTAL_GB GB
|_$PRODUCT_B:           $PRODUCT_B_SIZE B       $PRODUCT_B_SIZE_MB MB    $PRODUCT_B_SIZE_GB GB
|_$SYSTEM_B:    $SYSTEM_B_SIZE B  $SYSTEM_B_SIZE_MB MB  $SYSTEM_B_SIZE_GB GB
|_$VENDOR_B:            $VENDOR_B_SIZE B       $VENDOR_B_SIZE_MB MB    $VENDOR_B_SIZE_GB GB

x-------------------------------------------x
          Generated lpmake command
x-------------------------------------------x

lpmake \
--metadata-size $METADATA_MAX_SIZE \
--super-name=$SUPER_PARTITION_NAME \
--device-size=$SUPER_SIZE \
--metadata-slots=$METADATA_SLOT_COUNT \
--group=$GROUP_MAIN_A_NAME:$GROUP_MAIN_A_MAX_SIZE \
--group=$GROUP_MAIN_B_NAME:$GROUP_MAIN_B_MAX_SIZE \
--image=$PRODUCT_A=./extracted/$PRODUCT_A.img \
--partition=$PRODUCT_A:$PRODUCT_A_ATTRIBUTES:$PRODUCT_A_SIZE:$GROUP_MAIN_A_NAME \
--image=$PRODUCT_B=./extracted/$PRODUCT_B.img \
--partition=$PRODUCT_B:$PRODUCT_B_ATTRIBUTES:$PRODUCT_B_SIZE:$GROUP_MAIN_B_NAME \
--image=$SYSTEM_A=./extracted/$SYSTEM_A.img \
--partition=$SYSTEM_A:$SYSTEM_A_ATTRIBUTES:$SYSTEM_A_SIZE:$GROUP_MAIN_A_NAME \
--image=$SYSTEM_B=./extracted/$SYSTEM_B.img \
--partition=$SYSTEM_B:$SYSTEM_B_ATTRIBUTES:$SYSTEM_B_SIZE:$GROUP_MAIN_B_NAME \
--image=$VENDOR_A=./extracted/$VENDOR_A.img \
--partition=$VENDOR_A:$VENDOR_A_ATTRIBUTES:$VENDOR_A_SIZE:$GROUP_MAIN_A_NAME \
--image=$VENDOR_B=./extracted/$VENDOR_B.img \
--partition=$VENDOR_B:$VENDOR_B_ATTRIBUTES:$VENDOR_B_SIZE:$GROUP_MAIN_B_NAME \
--virtual-ab \
--sparse \
--output ./out/new_super$HASHSTAMP.img

EOF
} >> $LOG_FILE
  return 0
}

dump_variables() {
  dump_log
  sed -n 's/[^ ]*=[^ ]*/\n&\n/gp' $SCRIPT_NAME | grep '=' | \
  awk -F'=' '{gsub(/[^A-Z_]/, "", $1); if ($1 != "") print $1}' | \
  sed 's/\($F\|NR\)//g' | sort -u | head -n -1 | \
  sed -e '3d' -e '/^F$/d' -e '/^IFS/d' -e '/^LP/d' >> $TMP_FILE2
  while IFS= read -r var_name; do
    if [ -n "$var_name" ] && [ "${var_name#\#}" = "$var_name" ]; then
    var_value=$(eval echo "\$$var_name")
    output+="$var_name=$var_value\n"
    fi
  done < $TMP_FILE2
  [ -n "$output" ] && { echo -e "$output" | grep -v "^_=" >> $LOG_FILE ; }
  rm -f $TMP_FILE2
  cat $LOG_FILE
  return 0
}

make_super() {
## Generate lpmake command from super & its sub partitions
  dump_log
  cat $LOG_FILE
  echo "\n------------------------------------"
  echo "Saved lpmake command to: ./$LOG_FILE\n"
  echo "Build new_super$HASHSTAMP.img ?"
  echo -n "[y/n]: "
  read make_new_super
  case "$make_new_super" in
      [Yy])
         echo "\n------------------------------------"
         echo "Building new_super$HASHSTAMP.img...\n"
         silence mkdir ./out
         eval $(sed -n '{127,148p}' $LOG_FILE)
         echo "\nGenerated new super!"
         main_menu
         ;;
      *) main_menu ;;
  esac
}

extract_img() {
## Extract super or sub-partitions of super
  if [ -f "./super.img" ]; then
      LOG+="\nFound super.img."
      if silence ls ./extracted/*.img ; then
          LOG+="\nImages are located in ./extracted \n"
          if [ "$init_job" -eq 1 ]; then
              init_job=0
              return 0
          fi
      else
          LOG+="\nNo partitions have been extracted.\n"
          if [ "$init_job" -eq 2 ]; then
              init_job=0
              return 0
          fi
      fi
      echo "Extract partitions from super.img ?"
      echo -n "[y/n]: "
      read input
      case "$input" in
          [Yy])
             echo "\nExtracting partitons from super.img...\n"
             $imjtool super.img extract
             init_job=1
             extract_img
             ;;
          *) main_menu ;;
      esac
  else
      echo "\nPull super.img from /dev/block/by-name/super ?"
      echo -n "[y/n]: "
      read input
      case "$input" in
          [Yy])
             echo "\ndumping /dev/block/by-name/super to ./super.img ..."
             dd if=/dev/block/by-name/super of=./super.img bs=4096 status=progress
             echo "\nsuper.img dumped! \n"
             extract_img
             ;;
          *) main_menu ;;
      esac
  fi
}

mount_img() {
## Mount images from ./extracted/ onto ./mounted/system
  silence mkdir -p ./mounted/system/vendor
  silence mkdir -p ./mounted/system/product
  silence mkdir -p ./extracted

  mount() {
    LOOP_DEVICE=$(sudo losetup -f)
    fallocate -l 2G ./extracted/$IMG_NAME.img
    resize2fs ./extracted/$IMG_NAME.img 2G
    sudo losetup $LOOP_DEVICE ./extracted/$IMG_NAME.img
    sudo mount -t ext4 -o rw $LOOP_DEVICE $MOUNT_POINT
    case "$(mountpoint -q "$MOUNT_POINT"; echo $?)" in
      0) echo "\n$IMG_NAME mounted successfully at: $MOUNT_POINT"; main_menu ;;
      *) printf '\nFailed to mount the image\n'; function4 ;;
    esac
  }
  echo "\nWhat partition would you like to mount?\n"
  echo "Available images:\n"
  ls -1 ./extracted | sed -e 's/\.img$//'
  echo -n "\n>> "
  read IMG_NAME
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" && mount ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" && mount ;;
    product*) MOUNT_POINT="./mounted/system/product" && mount ;;
    [qb]) echo "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo "\nUnknown image name\n$IMG_NAME" && mount_img ;;
  esac
}

unmount_img() {
## Unmount chosen .img from mount point
  unmount() {
    while ! umount "$MOUNT_POINT"; do
        echo "\nAttempting to unmount $IMG_NAME from $MOUNT_POINT\n"
    done
    echo "\nSuccessfully unmounted $IMG_NAME from $MOUNT_POINT"
    e2fsck -yf ./extracted/$IMG_NAME.img
    resize2fs -M ./extracted/$IMG_NAME.img
    main_menu
  }
  echo "\nWhat partition would you like to unmount?\n"
  echo "Currently mounted:\n"
  sudo busybox mount | grep /mounted/ | awk '{print $3}' | sed 's/.*\///'
  echo -n "\n>> "
  read IMG_NAME
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" && unmount ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" && unmount ;;
    product*) MOUNT_POINT="./mounted/system/product" && unmount ;;
    [qb]) echo "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo "\nUnknown mount directory:\n$IMG_NAME" && unmount_img ;;
  esac
}


#system /system ext4 rw wait,avb=vbmeta_system,logical,first_stage_mount,slotselect
#vendor /vendor ext4 rw wait,avb,logical,first_stage_mount,slotselect
#product /product ext4 rw wait,avb,logical,first_stage_mount,slotselect
#/dev/block/by-name/userdata /data ext4 noatime,nosuid,nodev,noauto_da_alloc,errors=panic,latemount,wait,check,reservedsize=128M,formattable,resize,,checkpoint=block,notencryptable

options_list() {
  func_acl() {
    ## Function access control
    input="$SCRIPT_NAME"
    deny="run_function detect_env detect_arch load_binaries \
      set_global_vars byte_calc bytes_to_mb bytes_to_gb b2mb \
      calculate_hash hash_changed refresh_sizes metadata parse \
      parse_tmp sanitize dump_variables init extract_size lpmake_cmd \
      function1 function2 function3 function4 function5 function6 \
      func_acl file_check options_list ascii_box ui_variables compare_hashes \
      find_hash_file find_log_file main_menu unmount mount dump_log \
      clean silence"
    allow=""
    list_func=$(grep '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()' "$input" | sed 's/^[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
    for func in $list_func; do case "$deny" in *"$func"*) ;; *) allowed_func="$allowed_func$func " ;; esac done
    allowed_func=$(echo "$allowed_func" | sed 's/ $//')
    echo "$allowed_func"
  }
  options=$(func_acl) ; user_input="true"
  echo "Available options:"
  i=1
  for option in $options; do
    echo "$i. $option"
    i=$((i + 1))
  done
  echo "q. Quit"
  echo ""
  echo -n ">> "
  read -r func_name
  if [ "$func_name" = "q" ]; then
    echo "\nExiting..."
    exit 0
  fi
  if [ "$func_name" -eq "$func_name" ] 2>/dev/null; then
    if [ "$func_name" -ge 1 ] && [ "$func_name" -le "$i" ]; then
      j=1
      for option in $options; do
      if [ "$j" = "$func_name" ]; then
        func_name=$option
        break
      fi
      j=$((j + 1))
      done
    fi
  fi
  for option in $options; do
    if [ "$func_name" = "$option" ]; then
      run_function "$func_name"
      return
    fi
  done
  echo "Invalid choice. Please try again."
  user_input="false"
}

ascii_box() {
  text_input="$1"
  max_width=$((COLUMNS - 8)) ; box_width=$max_width
  border=$(printf '%*s' "$((box_width-2))" | tr ' ' '=')
  print_border="x${border}x" ; content_width=$((box_width - 6))
  # Print the top of the box
  echo "$print_border"
  echo "|$(printf '%*s' "$((box_width-2))")|"
  line=""
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
  if [ -n "$line" ]; then
    padding=$(( (box_width - ${#line} - 2) / 2 ))
    printf "|%*s%s%*s|\n" $padding "" "$line" $((box_width - padding - ${#line} - 2)) ""
  fi
  echo "|$(printf '%*s' "$((box_width-2))")|"
  echo "$print_border"
}

main_menu() {
  run_function() { func_name="$1" ; shift ; "$func_name" "$@" ; }

  ascii_box "Super Edit v0.2 - Main Menu"
  echo "$ARCH | $DISPLAY_HASH \n$LOG"
  options_list

  [ $user_input = "false" ] && { main_menu ; } && return 0
}

file_check() {
  [ -f "./super.img" ] && { init_job=$(silence ls ./extracted/*.img && echo 1 || echo 2) ; extract_img ; return 0 ; }
   cowsay -f tux "No super.img found within super-edit !
          1] Continue without using a super.img \
          2] Pull or use super.img from device
          q] Quit super-edit"
    echo -n "Choice: "
    read input; case "$input" in
        1) main_menu ;; 2) extract_img ;; q) exit 0 ;; esac
}

init() { detect_env; calculate_hash; silence metadata;
  debug_mode() { LOG="\nInitialized Debug Mode." ; dump_variables ; file_check ; main_menu ; }
    [ "$start_option" = debug ] && { debug_mode ; return 0 ; }
  LOG="\nInitialized."
  file_check
}


## Start Options
start_option=$1

init
main_menu
