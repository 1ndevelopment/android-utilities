#!/usr/bin/env bash

# Set env vars
KERNEL_URL=https://github.com/1ndev-ui/Kernel-MT6765-4.19.191-Generic
KERNEL_BRANCH=4.19.191_mt6765_dev
GAS_URL=https://android.googlesource.com/platform/prebuilts/gas/linux-x86
GAS_BRANCH=master
CLANG_URL=https://github.com/1ndev-ui/android_prebuilts_clang_host_linux-x86_clang-6443078
CLANG_BRANCH=11.0.1
BUILD_FLAGS=$(echo "
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- \\
CROSS_COMPILE_ARM32=arm-linux-gnueabi- CC=clang LLVM=1 LLVM_IAS=1 LD=ld.lld \\
AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf \\
OBJSIZE=llvm-size STRIP=llvm-strip
")
KERNEL_DIR=$(pwd)/$KERNEL_BRANCH

# Grab prereqs
sudo apt-get update && sudo apt-get install -y \
build-essential bc curl git zip ftp gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi \
libssl-dev lftp zstd wget libfl-dev python2 python3 libarchive-tools device-tree-compiler

# Clone Kernel source
git clone --recursive --branch $KERNEL_BRANCH $KERNEL_URL $KERNEL_DIR --depth=1

# Grab toolchains
git clone --recursive --branch $GAS_BRANCH $GAS_URL $KERNEL_DIR/gas --depth=1
git clone --recursive --branch $CLANG_BRANCH $CLANG_URL $KERNEL_DIR/clang --depth=1

# Add toolchains to PATH
export PATH=$KERNEL_DIR/gas/bin:$KERNEL_DIR/gas:$PATH
export PATH=$KERNEL_DIR/clang/bin:$KERNEL_DIR/clang:$PATH
export LD_LIBRARY_PATH=$KERNEL_DIR/clang/lib64:$LD_LIBRARY_PATH

# Build from _defconfig
cd $KERNEL_DIR
make -j4 O=$KERNEL_DIR/out $BUILD_FLAGS k65v1_64_bsp_defconfig

# Build kernel
make -j4 O=$KERNEL_DIR/out $BUILD_FLAGS CONFIG_DEBUG_SECTION_MISMATCH=y
