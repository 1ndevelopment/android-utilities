rm $PREFIX/bin/crsh
{
cat << EOF
#!/system/bin/sh
[ -z "\$1" ] && echo "No OS provided.\n" && exit 0 || OS="\$1"
CHROOTFS="/data/local/tmp/\$OS"
TMPDIR="/data/data/com.termux/files/usr/tmp"
BB="sudo /data/adb/magisk/busybox"
unset LD_PRELOAD
\$BB mount -o remount,dev,suid /data
\$BB mount proc -t proc \$CHROOTFS/proc
\$BB mount sys -t sysfs \$CHROOTFS/sys
\$BB mount --bind /dev \$CHROOTFS/dev
\$BB mount --bind /dev/pts \$CHROOTFS/dev/pts
\$BB mount --bind \$TMPDIR \$CHROOTFS/tmp
\$BB mount -t tmpfs -o size=256M tmpfs \$CHROOTFS/dev/shm
\$BB mount --bind /sdcard \$CHROOTFS/sdcard
#\$BB mount --bind /system \$CHROOTFS/system
#\$BB mount --bind /data \$CHROOTFS/data
#\$BB mount --bind /mnt/media_rw/0711-1519 \$CHROOTFS/external_sd
if [ -z "\$2" ]; then
  echo "Entering Shell\n"
  user=root
  \$BB chroot \$CHROOTFS /bin/su - \$user
else
  CMD="\$2"
  user=root
  if [ "\$CMD" = "GUI" ]; then
    kill -9 \$(pgrep -f "termux.x11") 2>/dev/null
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
    export XDG_RUNTIME_DIR=\${TMPDIR}
    termux-x11 :1 -ac >/dev/null & sleep 3
    MESA_NO_ERROR=1
    MESA_GL_VERSION_OVERRIDE=4.3COMPAT
    MESA_GLES_VERSION_OVERRIDE=3.2
    GALLIUM_DRIVER=zink
    ZINK_DESCRIPTORS=lazy
    virgl_test_server --use-egl-surfaceless --use-gles &
    crsh "\$OS" "kill -9 \$(pgrep -f termux.x11)" > /dev/null 2>&1
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1
    run() {
      crsh "\$OS" "export DISPLAY=:0 && export PULSE_SERVER=127.0.0.1 && dbus-launch --exit-with-session startxfce4" > /dev/null 2>&1
      pkill virgl_test_server /dev/null 2>&1
      pkill virglrender /dev/null 2>&1
    }
    run &
    exit 0
  fi
  \$BB chroot \$CHROOTFS /bin/su - \$user -c \$CMD
fi
\$BB umount \$CHROOTFS/proc -lf
\$BB umount \$CHROOTFS/sys -lf
\$BB umount \$CHROOTFS/dev/shm -lf
\$BB umount \$CHROOTFS/dev/pts -lf
\$BB umount \$CHROOTFS/dev -lf
\$BB umount \$CHROOTFS/tmp -lf
\$BB umount \$CHROOTFS/sdcard -lf
#\$BB umount \$CHROOTFS/system -lf
#\$BB umount \$CHROOTFS/data -lf
#\$BB umount \$CHROOTFS/external_sd -lf
pkill -f "app_process / com.termux.x11"
exit 0
EOF
} > $PREFIX/bin/crsh
chmod +x $PREFIX/bin/crsh
