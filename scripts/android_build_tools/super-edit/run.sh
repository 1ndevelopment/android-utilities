#!/system/bin/sh

alias lpadd="./bin/lpadd"
alias lpdump="./bin/lpdump"
alias lpflash="./bin/lpflash"
alias lpmake="./bin/lpmake"
alias lpunpack="./bin/lpunpack"
alias imjtool="./bin/imjtool"
alias img2simg="./bin/img2simg"
alias simg2img="./bin/simg2img"

cleanup() {
  echo "\nCleaning up workspace...\n"
  rm -rf ./extracted >/dev/null 2>&1
  rm -rf ./mounted >/dev/null 2>&1
  rm ./.log >/dev/null 2>&1
  rm ./super.log >/dev/null 2>&1
  rm ./.previous_hash >/dev/null 2>&1
}

generate_log() {
  touch .log
  if [ -f "./extracted/*.img" ]; then
    rm .log >/dev/null 2>&1
    cd extracted/ && stat -c '%n %s' *.img >> ../.log
    totalimgsize=$(cat ../.log|awk '{printf"%s""+",$2}'|sed 's/...$//'|bc)
    superimgsize=$(stat -c '%n %s' ../super.img|awk '{print $2}')
    cd .. && echo "\nTotal Image Size: $totalimgsize" >> .log
    echo "\nSuper Image Size: $superimgsize" >> .log
    echo "\n------------------------\n" >> .log
    lpdump >> .log
  else
    echo "\nNo extracted .img's found within ./extracted/"
    echo "Only some information will be displayed.\n"
    echo "Would you like to extract .img's from super.img now? [y/n]\n"
    read log_input1
    case "$log_input1" in
        [Yy]*) function2 ;;
        *) return 0 ;;
    esac
  fi
}

b2mb() {
input=$1
  bytes_to_mb() {
    echo "scale=2; $1 / (1024*1024)" | bc
  }
  bytes_to_gb() {
    echo "scale=2; $1 / (1024*1024*1024)" | bc
  }
mb_result=$(bytes_to_mb $input)
gb_result=$(bytes_to_gb $input)
}

calculate_hash() {
  # File to check
  FILE=".log"
  # File to store the previous hash
  HASH_FILE=".previous_hash"
  current_hash=$(sha256sum "$FILE" 2>/dev/null | awk '{print substr($1, 1, 7)}')
  hash_changed() {
      echo "The hash of $FILE has changed.\n"
      echo "Previous hash: $previous_log"
      echo "Current hash:  $current_hash"
      # Add any other actions you want to perform when the hash changes
  }
  # Check if the file exists
   if [ ! -f "$FILE" ]; then
     echo "Generating $FILE..."
     generate_log
  fi
  # Check if the previous hash file exists
  if [ -f "$HASH_FILE" ]; then
     previous_log=$(cat "$HASH_FILE")
     # Compare the hashes
     if [ "$current_hash" != "$previous_log" ]; then
         hash_changed
     else
         echo "The hash logs have not changed."
         echo "Current hash: $current_hash\n"
         echo "Starting..."
     fi
  else
     echo "\nNo previous hash found. This might be the first run.\n"
     echo "Starting...\n"
  fi
# Save the current hash for future comparisons
echo "$current_hash" > "$HASH_FILE"
HASHSTAMP=$(echo _$current_hash)
}

metadata() {
PRODUCT_A_ATTRIBUTES=$(echo "$(head -n 23 < .log | tail -n 1)" | awk '{sub(/^  Attributes: /, ""); print}')
PRODUCT_A_EXTENTS=$(head -n 25 < .log | tail -n 1)
PRODUCT_B_ATTRIBUTES=$(echo "$(head -n 29 < .log | tail -n 1)" | awk '{sub(/^  Attributes: /, ""); print}')
PRODUCT_B_EXTENTS=""
SYSTEM_A_ATTRIBUTES=$(echo "$(head -n 34 < .log | tail -n 1)" | awk '{sub(/^  Attributes: /, ""); print}')
SYSTEM_A_EXTENTS=$(head -n 36 < .log | tail -n 1)
SYSTEM_B_ATTRIBUTES=$(echo "$(head -n 40 < .log | tail -n 1)" | awk '{sub(/^  Attributes: /, ""); print}')
SYSTEM_B_EXTENTS=$(head -n 42 < .log | tail -n 1)
VENDOR_A_ATTRIBUTES=$(echo "$(head -n 46 < .log | tail -n 1)" | awk '{sub(/^  Attributes: /, ""); print}')
VENDOR_A_EXTENTS=$(head -n 48 < .log | tail -n 1)
VENDOR_B_ATTRIBUTES=$(echo "$(head -n 52 < .log | tail -n 1)" | awk '{sub(/^  Attributes: /, ""); print}')
VENDOR_B_EXTENTS=""
SUPER_PARTITION_NAME=$(echo "$(tail -n 19 < .log | head -n 1)" | awk '{sub(/^  Partition name: /, ""); print}')
LPDUMP_METADATA_INFO=$(lpdump | head -n 5)
LPDUMP_PARTITION_TABLE=$(awk "NR==12 {print}" .log && lpdump | tail -n 64 | head -n 36)
LPDUMP_SUPER_LAYOUT=$(lpdump | tail -n 26 | head -n 4 | sed 's/^super: //')
LPDUMP_BLOCK_DEVICE_TABLE=$(lpdump | tail -n 19 | head -n 4 | sed 's/^  *//')
LPDUMP_GROUP_TABLE=$(lpdump | tail -n 15)
  extract_size() {
      echo "$1" | awk '{print $2}'
  }
  extract_size3() {
      echo "$1" | awk '{print $3}'
  }
  extract_size4() {
      echo "$1" | awk '{print $4}'
  }
while read -r line; do
    case "$line" in
        "Super Image Size:"*) export TOTAL_SUPER_SIZE=$(extract_size4 "$line") ;;
        "Total Image Size:"*) export SUPER_SIZE=$(extract_size4 "$line") ;;
        "Metadata version:"*) export METADATA_VERSION=$(extract_size3 "$line") ;;
        "Metadata size:"*) export METADATA_SIZE=$(extract_size3 "$line") ;;
        "Metadata max size:"*) export METADATA_MAX_SIZE=$(extract_size4 "$line") ;;
        "Metadata slot count:"*) export METADATA_SLOT_COUNT=$(extract_size4 "$line") ;;
        "Header flags:"*) export HEADER_FLAGS=$(extract_size3 "$line") ;;
        "Name: product_a"*) export PRODUCT_A=$(extract_size "$line") ;;
        product_a.img*) export PRODUCT_A_SIZE=$(extract_size "$line") ;;
        "Name: product_b"*) export PRODUCT_B=$(extract_size "$line") ;;
        product_b.img*) export PRODUCT_B_SIZE=$(extract_size "$line") ;;
        "Name: system_a"*) export SYSTEM_A=$(extract_size "$line") ;;
        system_a.img*) export SYSTEM_A_SIZE=$(extract_size "$line") ;;
        "Name: system_b"*) export SYSTEM_B=$(extract_size "$line") ;;
        system_b.img*) export SYSTEM_B_SIZE=$(extract_size "$line") ;;
        "Name: vendor_a"*) export VENDOR_A=$(extract_size "$line") ;;
        vendor_a.img*) export VENDOR_A_SIZE=$(extract_size "$line") ;;
        "Name: vendor_b"*) export VENDOR_B=$(extract_size "$line") ;;
        vendor_b.img*) export VENDOR_B_SIZE=$(extract_size "$line") ;;
        "Group table:"*) ;;
        "Name: "*)
            current_group=$(extract_size "$line")
            case "$current_group" in
                "default") GROUP_DEFAULT_NAME=$current_group ;;
                "main_a") GROUP_MAIN_A_NAME=$current_group ;;
                "main_b") GROUP_MAIN_B_NAME=$current_group ;;
            esac
            ;;
        "Maximum size: "*)
            size=$(extract_size3 "$line")
            case "$current_group" in
                "default") GROUP_DEFAULT_MAX_SIZE=$size ;;
                "main_a") GROUP_MAIN_A_MAX_SIZE=$size ;;
                "main_b") GROUP_MAIN_B_MAX_SIZE=$size ;;
            esac
            ;;
        "Flags: "*)
            flags=$(extract_size "$line")
            case "$current_group" in
                "default") GROUP_DEFAULT_FLAGS=$flags ;;
                "main_a") GROUP_MAIN_A_FLAGS=$flags ;;
                "main_b") GROUP_MAIN_B_FLAGS=$flags ;;
            esac
            ;;
    esac
done < ./.log
PRODUCT_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $PRODUCT_B_SIZE" | bc)
SYSTEM_TOTAL_SIZE=$(echo "$SYSTEM_A_SIZE + $SYSTEM_B_SIZE" | bc)
VENDOR_TOTAL_SIZE=$(echo "$VENDOR_A_SIZE + $VENDOR_B_SIZE" | bc)
MAIN_A_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $SYSTEM_A_SIZE + $VENDOR_A_SIZE" | bc)
MAIN_B_TOTAL_SIZE=$(echo "$PRODUCT_A_SIZE + $SYSTEM_A_SIZE + $VENDOR_A_SIZE" | bc)
PRODUCT_TOTAL_MB=$(b2mb "$PRODUCT_TOTAL_SIZE" && echo "$mb_result MB")
SYSTEM_TOTAL_MB=$(b2mb "$SYSTEM_TOTAL_SIZE" && echo "$mb_result MB")
VENDOR_TOTAL_MB=$(b2mb "$VENDOR_TOTAL_SIZE" && echo "$mb_result MB")
MAIN_A_TOTAL_MB=$(b2mb "$MAIN_A_TOTAL_SIZE" && echo "$mb_result MB")
MAIN_B_TOTAL_MB=$(b2mb "$MAIN_B_TOTAL_SIZE" && echo "$mb_result MB")
SUPER_TOTAL_MB=$(b2mb "$TOTAL_SUPER_SIZE" && echo "$mb_result MB")
PRODUCT_TOTAL_GB=$(b2mb "$PRODUCT_TOTAL_SIZE" && echo "$gb_result GB")
SYSTEM_TOTAL_GB=$(b2mb "$SYSTEM_TOTAL_SIZE" && echo "$gb_result GB")
VENDOR_TOTAL_GB=$(b2mb "$VENDOR_TOTAL_SIZE" && echo "$gb_result GB")
MAIN_A_TOTAL_GB=$(b2mb "$MAIN_A_TOTAL_SIZE" && echo "$gb_result GB")
MAIN_B_TOTAL_GB=$(b2mb "$MAIN_B_TOTAL_SIZE" && echo "$gb_result GB")
SUPER_TOTAL_GB=$(b2mb "$TOTAL_SUPER_SIZE" && echo "$gb_result GB")
PRODUCT_A_SIZE_MB=$(b2mb "$PRODUCT_A_SIZE" && echo "$mb_result MB")
PRODUCT_A_SIZE_GB=$(b2mb "$PRODUCT_A_SIZE" && echo "$gb_result GB")
PRODUCT_B_SIZE_MB=$(b2mb "$PRODUCT_B_SIZE" && echo "$mb_result MB")
PRODUCT_B_SIZE_GB=$(b2mb "$PRODUCT_B_SIZE" && echo "$gb_result GB")
SYSTEM_A_SIZE_MB=$(b2mb "$SYSTEM_A_SIZE" && echo "$mb_result MB")
SYSTEM_A_SIZE_GB=$(b2mb "$SYSTEM_A_SIZE" && echo "$gb_result GB")
SYSTEM_B_SIZE_MB=$(b2mb "$SYSTEM_B_SIZE" && echo "$mb_result MB")
SYSTEM_B_SIZE_GB=$(b2mb "$SYSTEM_B_SIZE" && echo "$gb_result GB")
VENDOR_A_SIZE_MB=$(b2mb "$VENDOR_A_SIZE" && echo "$mb_result MB")
VENDOR_A_SIZE_GB=$(b2mb "$VENDOR_A_SIZE" && echo "$gb_result GB")
VENDOR_B_SIZE_MB=$(b2mb "$VENDOR_B_SIZE" && echo "$mb_result MB")
VENDOR_B_SIZE_GB=$(b2mb "$VENDOR_B_SIZE" && echo "$gb_result MB")
}

generate_super_partition_table() {

  rm super.log >/dev/null 2>&1

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
            $PRODUCT_A_SIZE_MB
            $PRODUCT_A_SIZE_GB

      Extents:
  $PRODUCT_A_EXTENTS

* Name: $PRODUCT_B
   Group: $GROUP_MAIN_B_NAME
     Attributes: $PRODUCT_B_ATTRIBUTES
      Size: $PRODUCT_B_SIZE B
            $PRODUCT_B_SIZE_MB
            $PRODUCT_B_SIZE_GB

      Extents:
  $PRODUCT_B_EXTENTS

* Product Total: $PRODUCT_TOTAL_SIZE B
                 $PRODUCT_TOTAL_MB
                 $PRODUCT_TOTAL_GB

* Name: $SYSTEM_A
   Group: $GROUP_MAIN_A_NAME
     Attributes: $SYSTEM_A_ATTRIBUTES
      Size: $SYSTEM_A_SIZE B
            $SYSTEM_A_SIZE_MB
            $SYSTEM_A_SIZE_GB

      Extents:
  $SYSTEM_A_EXTENTS

* Name: $SYSTEM_B
   Group: $GROUP_MAIN_B_NAME
     Attributes: $SYSTEM_B_ATTRIBUTES
      Size: $SYSTEM_B_SIZE B
            $SYSTEM_B_SIZE_MB
            $SYSTEM_B_SIZE_GB

      Extents:
  $SYSTEM_B_EXTENTS

* System Total: $SYSTEM_TOTAL_SIZE B
                $SYSTEM_TOTAL_MB
                $SYSTEM_TOTAL_GB

* Name: $VENDOR_A
   Group: $GROUP_MAIN_A_NAME
     Attributes: $VENDOR_A_ATTRIBUTES
      Size: $VENDOR_A_SIZE B
            $VENDOR_A_SIZE_MB
            $VENDOR_A_SIZE_GB

      Extents:
  $VENDOR_A_EXTENTS

* Name: $VENDOR_B
   Group: $GROUP_MAIN_B_NAME
     Attributes: $VENDOR_B_ATTRIBUTES
      Size: $VENDOR_B_SIZE B
            $VENDOR_B_SIZE_MB
            $VENDOR_B_SIZE_GB

      Extents:
  $VENDOR_B_EXTENTS

* Vendor Total: $VENDOR_TOTAL_SIZE B
                $VENDOR_TOTAL_MB
                $VENDOR_TOTAL_GB

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

$LPDUMP_METADATA_INFO

$LPDUMP_BLOCK_DEVICE_TABLE

$LPDUMP_SUPER_LAYOUT

$SUPER_PARTITION_NAME:        $TOTAL_SUPER_SIZE B $SUPER_TOTAL_MB $SUPER_TOTAL_GB

$GROUP_MAIN_A_NAME:       $MAIN_A_TOTAL_SIZE B $MAIN_A_TOTAL_MB $MAIN_A_TOTAL_GB
|_$PRODUCT_A:  $PRODUCT_A_SIZE B $PRODUCT_A_SIZE_MB $PRODUCT_A_SIZE_GB
|_$SYSTEM_A:   $SYSTEM_A_SIZE B $SYSTEM_A_SIZE_MB $SYSTEM_A_SIZE_GB
|_$VENDOR_A:    $VENDOR_A_SIZE B  $VENDOR_A_SIZE_MB  $VENDOR_A_SIZE_GB

$GROUP_MAIN_B_NAME:       $MAIN_B_TOTAL_SIZE B $MAIN_B_TOTAL_MB $MAIN_B_TOTAL_GB
|_$PRODUCT_B:           $PRODUCT_B_SIZE B       $PRODUCT_B_SIZE_MB    $PRODUCT_B_SIZE_GB
|_$SYSTEM_B:    $SYSTEM_B_SIZE B  $SYSTEM_B_SIZE_MB  $SYSTEM_B_SIZE_GB
|_$VENDOR_B:            $VENDOR_B_SIZE B       $VENDOR_B_SIZE_MB    $VENDOR_B_SIZE_GB

x-------------------------------------------x
EOF
} > super.log

  cat super.log

}

generate_lpmake_command() {
  rm super.log >/dev/null 2>&1 && generate_super_partition_table
  LPMAKE_COMMAND=$(cat << EOF
lpmake \\
--metadata-size $METADATA_MAX_SIZE \\
--super-name=$SUPER_PARTITION_NAME \\
--device-size=$TOTAL_SUPER_SIZE \\
--metadata-slots=$METADATA_SLOT_COUNT \\
--group=$GROUP_MAIN_A_NAME:$GROUP_MAIN_A_MAX_SIZE \\
--group=$GROUP_MAIN_B_NAME:$GROUP_MAIN_B_MAX_SIZE \\
--image=$PRODUCT_A=./extracted/$PRODUCT_A.img \\
--partition=$PRODUCT_A:$PRODUCT_A_ATTRIBUTES:$PRODUCT_A_SIZE:$GROUP_MAIN_A_NAME \\
--image=$PRODUCT_B=./extracted/$PRODUCT_B.img \\
--partition=$PRODUCT_B:$PRODUCT_B_ATTRIBUTES:$PRODUCT_B_SIZE:$GROUP_MAIN_B_NAME \\
--image=$SYSTEM_A=./extracted/$SYSTEM_A.img \\
--partition=$SYSTEM_A:$SYSTEM_A_ATTRIBUTES:$SYSTEM_A_SIZE:$GROUP_MAIN_A_NAME \\
--image=$SYSTEM_B=./extracted/$SYSTEM_B.img \\
--partition=$SYSTEM_B:$SYSTEM_B_ATTRIBUTES:$SYSTEM_B_SIZE:$GROUP_MAIN_B_NAME \\
--image=$VENDOR_A=./extracted/$VENDOR_A.img \\
--partition=$VENDOR_A:$VENDOR_A_ATTRIBUTES:$VENDOR_A_SIZE:$GROUP_MAIN_A_NAME \\
--image=$VENDOR_B=./extracted/$VENDOR_B.img \\
--partition=$VENDOR_B:$VENDOR_B_ATTRIBUTES:$VENDOR_B_SIZE:$GROUP_MAIN_B_NAME \\
--virtual-ab \\
--sparse \\
--output ./out/new_super$HASHSTAMP.img
EOF)
  echo "\n$LPMAKE_COMMAND" | tee -a super.log
}

function1() {
  cleanup
  function0
}

cleanup() {
  echo "\nCleaning up workspace...\n"
  rm -rf ./extracted >/dev/null 2>&1
  rm -rf ./mounted >/dev/null 2>&1
  rm ./.log >/dev/null 2>&1
  rm ./super.log >/dev/null 2>&1
  rm ./.previous_hash >/dev/null 2>&1
}

function2() {
  # Check if super.img exists in the script's directory
  if [ -f "./super.img" ]; then
      echo "\nsuper.img found."
      echo "Extract partitions from super.img ? [y/n] \n"
      read "$input"
      case "$input" in
          [Yy])
             echo "Extracting partitons from super.img...\n"
             imjtool ./super.img extract
             return 0
             ;;
          *) function0 ;;
      esac
  else
      echo "\nPull super.img from /dev/block/by-name/super ? [y/n] \n"
      read input
      case "$input" in
          [Yy])
             echo "\ndumping /dev/block/by-name/super to ./super.img ..."
             dd if=/dev/block/by-name/super of=./super.img bs=4096 status=progress
             return 0
             ;;
          *) function0 ;;
      esac
  fi
}

function3() {
  generate_super_partition_table
  echo "\nSaved to Super Info to ./super.log"
  echo "\nReturn to Main Menu? [y/n]\n"
  read input
  case "$input" in
      [Yy]) function0 ;;
      *) function3 ;;
  esac
}

function4() {
  mkdir -p ./mounted/system/vendor >/dev/null 2>&1
  mkdir -p ./mounted/system/product >/dev/null 2>&1
  ## mount images from extracted onto ./mounted/system
  echo "\nWhat partition would you like to mount?"
  echo "\nAvailable images:\n"
  ls -1 ./extracted | sed -e 's/\.img$//'
  echo "\nb) Go back\n"
  read IMG_NAME
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" ;;
    product*) MOUNT_POINT="./mounted/system/product" ;;
    b) echo "\nHeading back to Main Menu...\n" && function0 ;;
    *) echo "\nUnknown image name\n$IMG_NAME" && exit 1 ;;
  esac
  if [[ $IMG_NAME != *_b.img ]]; then
    LOOP_DEVICE=$(sudo losetup -f)
    sudo losetup $LOOP_DEVICE ./extracted/$IMG_NAME.img
    sudo mount -t ext4 -o rw $LOOP_DEVICE $MOUNT_POINT
    if mountpoint -q $MOUNT_POINT; then
      echo "\nImage mounted successfully at $MOUNT_POINT\n"
      function0
    else
      echo "\nFailed to mount the image\n"
    fi
  fi
}

function5() {
  ## unmount images from mounted dir
  echo "\nWhat partition would you like to unmount?\n"
  echo "\nCurrently mounted:\n"
  sudo busybox mount | grep /mounted/ | awk '{print $3}' | sed 's/.*\///'
  echo "\nb) Go back\n"
  read IMG_NAME
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" ;;
    product*) MOUNT_POINT="./mounted/system/product" ;;
    b) echo "\nHeading back to Main Menu...\n" && function0 ;;
    *) echo "\nUnknown mount directory:\n$IMG_NAME" && exit 1 ;;
  esac
  if [[ $IMG_NAME != *_b.img ]]; then
    while ! umount $MOUNT_POINT
    do
       echo "\nAttempting to unmount $IMG_NAME from $MOUNT_POINT\n"
    done
    echo "\nUnmounted $MOUNT_POINT\n"
  function5
  fi
}

function6() {
  generate_lpmake_command
  echo "\n------------------------"
  echo "Saved lpmake command to: ./super.log\n"
  echo "Would you like to make a new_super.img ? [y/n] \n"
  read make_new_super
  if [[ $make_new_super == "Y" || $make_new_super == "y" ]]; then
    echo "\n------------------------\n"
    echo "Building new_super.img...\n"
    eval "$LPMAKE_COMMAND"
    mkdir ./out >/dev/null 2>&1
    echo "\nGenerated new super!"
    mv ./new_super.img ./out/new_super"$HASHSTAMP".img
  else
    function0
  fi
}

function0() {
  echo "\nSuper Edit v0.1 - Main Menu"
  echo "\nx===========================================x"
  echo "| 1) Cleanup 2) Extract Super 3) IMG Info   |"
  echo "| 4) Mount IMG 5) Unmount IMG 6) Make Super |"
  echo "| q) Quit                                   |"
  echo "x===========================================x\n"
  read input
  case "$input" in
      [0-6]) function"$input" ;;
      q) exit 0 ;;
  esac
}

init() {
  if [ -f "./super.img" ]; then
    calculate_hash \ metadata >/dev/null 2>&1 \ function0
  else
    echo ""
    echo "super.img not found in the super-edit directory.\n"
    echo "1) Continue without a super.img"
    echo "2) Pull super.img"
    echo "q) Quit \n"
    read input
    case "$input" in
        1) function0 ;;
        2) function2 ;;
        b) return 0 ;;
    esac
  fi
}

init
exit 0
