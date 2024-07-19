#!/usr/bin/env bash

# Grab prereqs

sudo apt-get update && sudo apt-get install -y build-essential bc curl git zip ftp gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi libssl-dev lftp zstd wget libfl-dev python2 python3 libarchive-tools device-tree-compiler zsh

# Clone Kernel source

git clone --recursive --branch 4.19.191_mt6765_dev https://github.com/1ndev-ui/Kernel-MT6765-4.19.191-Generic 4.19.191_mt6765 --depth=1

cd 4.19.191_mt6765

# Grab toolchains

git clone --recursive --branch master https://android.googlesource.com/platform/prebuilts/gas/linux-x86 gas --depth=1

git clone --recursive --branch 11.0.1 https://github.com/1ndev-ui/android_prebuilts_clang_host_linux-x86_clang-6443078 clang --depth=1

# Add toolchains to PATH

export PATH=/home/runner/work/Runner-Box/Runner-Box/4.19.191_mt6765/clang/bin:/home/runner/work/Runner-Box/4.19.191_mt6765/clang:/home/runner/work/Runner-Box/4.19.191_mt6765/gas/bin:/home/runner/work/Runner-Box/4.19.191_mt6765/gas:$PATH

export LD_LIBRARY_PATH=/home/runner/work/Runner-Box/Runner-Box/4.19.191_mt6765/clang/lib64:$$LD_LIBRARY_PATH

# Build from _defconfig

make -j4 O=/home/runner/work/Runner-Box/Runner-Box/out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CC=clang LLVM=1 LLVM_IAS=1 LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf OBJSIZE=llvm-size STRIP=llvm-strip k65v1_64_bsp_defconfig

# Build kernel

make -j4 O=/home/runner/work/Runner-Box/Runner-Box/out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CC=clang LLVM=1 LLVM_IAS=1 LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf OBJSIZE=llvm-size STRIP=llvm-strip CONFIG_DEBUG_SECTION_MISMATCH=y


