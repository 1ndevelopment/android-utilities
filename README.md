![alt text](https://files.1ndev.com/api/public/dl/32-gcNIr)

# android-utilities
Various termux scripts, magisk modules &amp; tools.

```
.
├── README.md
├── bin
│   ├── arm
│   │   ├── android
│   │   │   ├── img2simg
│   │   │   ├── make_ext4fs
│   │   │   ├── sefcontext_decompile
│   │   │   └── simg2img
│   │   ├── img2simg
│   │   ├── make_ext4fs
│   │   ├── sefcontext_decompile
│   │   └── simg2img
│   ├── arm64
│   │   ├── android
│   │   │   ├── avbctl
│   │   │   ├── binrun
│   │   │   ├── bootctl
│   │   │   ├── busybox
│   │   │   ├── dextra
│   │   │   ├── erofs
│   │   │   ├── getcon
│   │   │   ├── img2simg
│   │   │   ├── imjtool
│   │   │   ├── lpadd
│   │   │   ├── lpdump
│   │   │   ├── lpflash
│   │   │   ├── lpmake
│   │   │   ├── lpunpack
│   │   │   ├── magiskboot
│   │   │   ├── make_ext4fs
│   │   │   ├── megatools
│   │   │   ├── parted
│   │   │   ├── pigz
│   │   │   ├── sefcontext_decompile
│   │   │   ├── setcon
│   │   │   ├── simg2img
│   │   │   └── tree
│   │   ├── img2simg
│   │   ├── lib
│   │   │   ├── libc++_shared.so
│   │   │   └── libz.so.1
│   │   ├── make_ext4fs
│   │   ├── sefcontext_decompile
│   │   └── simg2img
│   ├── x86
│   │   ├── android
│   │   │   ├── img2simg
│   │   │   ├── make_ext4fs
│   │   │   ├── sefcontext_decompile
│   │   │   └── simg2img
│   │   ├── img2simg
│   │   ├── make_ext4fs
│   │   ├── sefcontext_decompile
│   │   └── simg2img
│   └── x86_64
│       ├── android
│       │   ├── img2simg
│       │   ├── make_ext4fs
│       │   ├── sefcontext_decompile
│       │   └── simg2img
│       ├── img2simg
│       ├── make_ext4fs
│       ├── payload-dumper
│       ├── sefcontext_decompile
│       └── simg2img
├── build-apk-tool
│   └── build_apk.sh
├── bulk_apk_installer.sh
├── enable-exfat-tool
│   ├── 0_uninstall.sh
│   ├── 1_install.sh
│   ├── 2_install.sh
│   ├── exfat_USB.sh
│   ├── mount.exfat
│   ├── ntfs-3g
│   ├── ntfsfix
│   └── probe
├── info.sh
├── ota-flashable-zip-template-tool
│   ├── Firmware
│   │   ├── place_firmware.imgs_here
│   │   └── super.img
│   ├── META-INF
│   │   └── com
│   │       └── google
│   │           └── android
│   │               └── update-binary
│   ├── bin -> ../bin
│   └── package_ota.sh
├── proot_installer.sh
├── scripts
│   ├── 0001_fix_sepolicy.sh
│   ├── adb_zsh_termux_shell.sh
│   ├── build_bliss_rom.sh
│   ├── build_kernel.sh
│   ├── change_build_usr2eng.sh
│   ├── fw_dump.sh
│   ├── generate_sha256_lists.sh
│   ├── install_scrcpy.sh
│   ├── ohmyzsh_termux_install.sh
│   ├── recovery_mode_usb-mtp-fix.sh
│   ├── remount_rw.sh
│   └── xfce_termux-x11_install.sh
├── super-edit-tool
│   ├── bin -> ../bin
│   └── super_edit.sh
└── termux_backup_tool.sh
```

# Build APK Tool

# Bulk APK Installer

# Enable EXFat Tool

# Custom Recovery Flashable .ZIP Builder

# Termux Proot Installer
## Features:

* Easy to use

* Automatic Install

## Installation

1] Select your distro
2] Type in your username and password
3] Once finished, simply run: run-$os-x11

# Super Edit Tool
