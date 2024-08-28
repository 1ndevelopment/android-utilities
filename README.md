![alt text](https://files.1ndev.com/api/public/dl/32-gcNIr)

# Android Utilities
Various termux scripts, binaries &amp; tools.

## Included Binaries
```
android-utilities
└── bin
    ├── arm
    │   ├── android
    │   │   ├── img2simg
    │   │   ├── make_ext4fs
    │   │   ├── sefcontext_decompile
    │   │   └── simg2img
    │   ├── img2simg
    │   ├── make_ext4fs
    │   ├── sefcontext_decompile
    │   └── simg2img
    ├── arm64
    │   ├── android
    │   │   ├── avbctl
    │   │   ├── binrun
    │   │   ├── bootctl
    │   │   ├── busybox
    │   │   ├── dextra
    │   │   ├── erofs
    │   │   ├── getcon
    │   │   ├── img2simg
    │   │   ├── imjtool
    │   │   ├── lpadd
    │   │   ├── lpdump
    │   │   ├── lpflash
    │   │   ├── lpmake
    │   │   ├── lpunpack
    │   │   ├── magiskboot
    │   │   ├── make_ext4fs
    │   │   ├── megatools
    │   │   ├── parted
    │   │   ├── pigz
    │   │   ├── sefcontext_decompile
    │   │   ├── setcon
    │   │   ├── simg2img
    │   │   └── tree
    │   ├── img2simg
    │   ├── lib
    │   │   ├── libc++_shared.so
    │   │   └── libz.so.1
    │   ├── make_ext4fs
    │   ├── sefcontext_decompile
    │   └── simg2img
    ├── x86
    │   ├── android
    │   │   ├── img2simg
    │   │   ├── make_ext4fs
    │   │   ├── sefcontext_decompile
    │   │   └── simg2img
    │   ├── img2simg
    │   ├── make_ext4fs
    │   ├── sefcontext_decompile
    │   └── simg2img
    └── x86_64
        ├── android
        │   ├── img2simg
        │   ├── make_ext4fs
        │   ├── sefcontext_decompile
        │   └── simg2img
        ├── img2simg
        ├── make_ext4fs
        ├── payload-dumper
        ├── sefcontext_decompile
        └── simg2img
```

## Build APK Tool
```
android-utilities
└── build-apk-tool
    └── ./build_apk.sh
```

## Bulk APK Installer
```
android-utilities
└── ./bulk_apk_installer.sh
```

## Enable EXFat Tool
```
android-utilities
└── enable-exfat-tool
    ├── ./0_uninstall.sh
    ├── ./1_install.sh
    ├── ./2_install.sh
    ├── ./exfat_USB.sh
    ├── mount.exfat
    ├── ntfs-3g
    ├── ntfsfix
    └── probe
```

## Recovery Flashable .zip Tool
```
android-utilities
└── ota-flashable-zip-template-tool
    ├── Firmware
    │   └── place_firmware.imgs_here
    ├── META-INF
    │   └── com
    │       └── google
    │           └── android
    │               └── update-binary
    ├── bin -> ../bin
    └── ./package_ota.sh
```

## Termux Proot Installer
```
android-utilities
└── ./proot_installer.sh
```

## Super Edit Tool
```
android-utilities
└── super-edit-tool
    ├── bin -> ../bin
    └── ./super_edit.sh
```

## Various Scripts
```
android-utilities
└── various-scripts
    ├── ./adb_zsh_termux_shell.sh
    ├── ./build_bliss_rom.sh
    ├── ./build_kernel.sh
    ├── ./change_build_usr2eng.sh
    ├── ./fw_dump.sh
    ├── ./generate_sha256_lists.sh
    ├── ./install_scrcpy.sh
    ├── ./ohmyzsh_termux_install.sh
    ├── ./recovery_mode_usb-mtp-fix.sh
    ├── ./remount_rw.sh
    ├── ./startup_fix_sepolicy.sh
    └── ./xfce_termux-x11_install.sh
```
