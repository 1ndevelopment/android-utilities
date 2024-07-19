#!/usr/bin/env bash

install_java_dep() {
echo ""
echo "x==========================x"
echo "| Installing OpenJDK 21... |"
echo "x==========================x"
echo ""

sudo apt-get update && sudo apt-get install openjdk-21-jdk -y && sudo apt-get upgrade -y
update-alternatives --config java 21
update-alternatives --config javac 21

echo ""
echo "x=====================================x"
echo "|            Reboot? [y/n]            |"
echo "| Only Needed for first time install. |"
echo "x=====================================x"
echo ""
read -p " :// " input

if [[ $input == "Y" || $input == "y" || $input == "yes"|| $input == "YES" ]]; then
   echo ""
   echo "rebooting!"
   echo ""
   reboot
   exit 0
fi

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"

logo
options
}

install_deps() {
echo ""
echo "x===================================x"
echo "| Installing needed dependencies... |"
echo "x===================================x"
echo ""

sudo apt-get update -y && sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip squashfs-tools python3-mako libssl-dev ninja-build lunzip syslinux syslinux-utils gettext genisoimage gettext bc xorriso xmlstarlet git-lfs -y bc g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev lib32ncurses5-dev libncurses5 libncurses5-dev python-is-python3 -y && sudo apt-get upgrade -y

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"

echo ""
echo "x==========================================x"
echo "| Currently Installed dependency versions: |"
echo "x==========================================x"
echo ""

git --version
echo ""
make --version
echo ""
zip --version
echo ""
curl --version
echo ""
gcc --version
echo ""
g++ --version
echo ""

logo
options
}

setup_env() {
echo ""
echo "x===========================x"
echo "| Setting up Environment... |"
echo "x===========================x"
echo ""

mkdir ~/workspace
git clone https://github.com/akhilnarang/scripts ~/workspace/scripts
bash ~/workspace/scripts/setup/android_build_env.sh

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"

echo ""
echo "x===================================================x"
echo "| Exporting ~/bin to PATH & Sourcing environment... |"
echo "x===================================================x"

echo "export PATH=~/bin:$PATH" >> ~/.bashrc
. ~/.bashrc

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"

echo ""
echo "x====================x"
echo "| Configuring git... |"
echo "x====================x"
echo ""

git config --global user.email "1ndevelopment@protonmail.com"
git config --global user.name "1ndev-ui"
git lfs install
git config --global trailer.changeid.key "Change-Id"

echo "x=======x"
echo "| Done! |"
echo "x=======x"

logo
options
}

setup_ccache() {
echo ""
echo "x======================x"
echo "| Setting up ccache... |"
echo "x======================x"
echo ""

mkdir -p ~/workspace/ccache
echo "export CCACHE_DIR=~/workspace/ccache/" >> ~/.bashrc
echo "export USE_CCACHE=1" >> ~/.bashrc
echo "export CCACHE_EXEC=$(which ccache)" >> ~/.bashrc
. ~/.bashrc

ccache -M 100G
ccache -o compression=true
ccache -s

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"
echo ""

logo
options
}

sync_manifest() {
echo ""
echo "x===========================================x"
echo "| Grabbing Bliss manifest & Syncing Repo... |"
echo "x===========================================x"
echo ""

mkdir -p ~/workspace/lineage
cd ~/workspace/lineage/

repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --git-lfs
repo sync -j10

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"

logo
options
}

dl_dt() {
echo ""
echo "x============================x"
echo "| Downloading Device Tree... |"
echo "x============================x"
echo ""

cd ~/workspace/lineage

git clone https://github.com/1ndev-ui/ROM_CG65_device_tree.git -b lineage-21.0 ./device/vortex/CG65
git clone https://github.com/1ndev-ui/vendor_vortex_CG65 -b lineage-21.0 ./vendor/vortex/CG65

echo ""
echo "x=======x"
echo "| Done! |"
echo "x=======x"

logo
options
}

build_rom_prompt() {
echo ""
echo "x==================x"
echo "| Build ROM? [y/n] |"
echo "x==================x"
echo ""
read -p ":// " buildrom

if [[ $buildrom == "Y" || $buildrom == "y" || $buildrom == "yes" || $buildrom == "YES" ]]; then
   build
fi

logo
options
}

build() {
echo ""
echo "x=================x"
echo "| Building ROM... |"
echo "x=================x"
echo ""

cd ~/workspace/lineage

#unset RELAX_USES_LIBRARY_CHECK
#export RELAX_USES_LIBRARY_CHECK=true #for CG65 device debugging

. build/envsetup.sh
breakfast CG65
mka -j10

echo ""
echo "x===================================x"
echo "|            Finished!              |"
echo "|                                   |"
echo "|         Built Bliss.zip in:       |"
echo "|   out/target/product/<Codename>/  |"
echo "|                                   |"
echo "x===================================x"
echo ""

logo
options
}

logo() {
echo ""
echo "      x===================================x"
echo "      | Custom ROM builder script (v0.01) |"
echo "      x===================================x"
echo ""
echo "            Written for Ubuntu 22.04"
}

options() {
echo ""
echo "x=================================================x"
echo "| 1) Install OpenJDK 21 | 2) Install Dependencies |"
echo "| 3) Setup Environment  | 4) Setup Ccache         |"
echo "| 5) Sync ROM Manifest  | 6) Grab Device Tree     |"
echo "| 7) Build ROM!         | q) Exit the script      |"
echo "x=================================================x"
echo ""

read -p ":// " option_input
case $option_input in
    1) install_java_dep ;;
    2) install_deps ;;
    3) setup_env ;;
    4) setup_ccache ;;
    5) sync_manifest ;;
    6) dl_dt ;;
    7) build_rom_prompt ;;
    0) echo "" && echo  "closing..." && exit 0 ;;
    q) echo "" && echo  "closing..." && exit 0 ;;
    *) echo "Invalid input" ;;
esac
}

logo
options
