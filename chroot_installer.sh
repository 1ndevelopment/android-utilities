#!/system/bin/sh

source $(realpath .env)

ascii_box "Chroot Linux Termux:x11 Installer"

OS="ubuntu"
CHROOTFS="/data/local/tmp/$OS"
PREFIX="/data/data/com.termux/files/usr"

setup_ubuntu() {
  install_rootfs() {
    mkdir -p $CHROOTFS/
    wget https://website.com/ -P ubuntu.tar.xz
    tar ./ubuntu.tar.xz -C $CHROOTFS/
    echo "$(getprop persist.sys.timezone)" > $CHROOTFS/etc/timezone
    echo "nameserver 8.8.8.8" > $CHROOTFS/etc/resolv.conf
    echo "127.0.0.1 localhost" > $CHROOTFS/etc/hosts
    silence mkdir -p $CHROOTFS/sdcard $CHROOTFS/system $CHROOTFS/data $CHROOTFS/media/external $CHROOTFS/dev/shm
    silence chown -R media_rw:media_rw $CHROOTFS/media/external
{
cat << EOF
#!/usr/bin/env bash
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
update_pkgs() { apt update -y && apt upgrade -y && apt autoremove -y ; }
update_pkgs
apt install -y sudo
sudo apt install -y git gcc build-essential cmake xfce4 xfce4-terminal dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev zenity software-properties-common mesa-utils kate fish lsd
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
update_pkgs
exit 0
EOF
} > "$CHROOTFS/root/update.sh"
    chmod +x "$CHROOTFS/root/update.sh"
    rm -r "$CHROOTFS/root/adduser.sh" >/dev/null 2>&1
{
cat << EOF
#!/usr/bin/env bash
func() {
  [ -n "\$user" ] && { printf "..." ; } || printf "\nEnter Username: " && read user && >
  if awk -F":" '{print \$1}' /etc/passwd | grep -q "\$user"; then
    printf "\nLogging in as \$user\n"
    echo "\$user" > "/root/.active_user"
  else
    printf "Password: " && read pass && printf ""
    groupadd storage && groupadd wheel
    useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "\$user"
    printf "%s:%s" "\$user" "\$pass" | chpasswd
    chmod u+rw /etc/sudoers
    printf "%s ALL=(ALL) ALL" "\$user" >> /etc/sudoers
    chmod u-w /etc/sudoers
    printf "\n\$user has been created!\n"
    exit 0
  fi
}
func
EOF
} > "$CHROOTFS/root/adduser.sh"
    chmod +x "$CHROOTFS/root/adduser.sh"
    rm -r $PREFIX/bin/crsh
{
cat << EOF
#!/system/bin/sh
[ -z "\$1" ] && echo "No OS provided.\n" && exit 0 || OS="\$1"
CHROOTFS="/data/local/tmp/\$OS"
TMPDIR="/data/data/com.termux/files/usr/tmp"
BB="/data/adb/magisk/busybox"
unset LD_PRELOAD
mount() {
  su -c "\$BB mount -o remount,dev,suid /data"
  su -c "\$BB mount proc -t proc \$CHROOTFS/proc >/dev/null 2>&1"
  su -c "\$BB mount sys -t sysfs \$CHROOTFS/sys >/dev/null 2>&1"
  su -c "\$BB mount --bind /dev \$CHROOTFS/dev"
  su -c "\$BB mount --bind /dev/pts \$CHROOTFS/dev/pts"
  su -c "\$BB mount --bind \$TMPDIR \$CHROOTFS/tmp"
  su -c "\$BB mount -t tmpfs -o size=256M tmpfs \$CHROOTFS/dev/shm"
#  su -c "\$BB mount --bind /system \$CHROOTFS/system"
#  su -c "\$BB mount --bind /data \$CHROOTFS/data"
#  su -c "\$BB mount --bind /storage/emulated/0 \$CHROOTFS/sdcard"
  su -c "\$BB mount --bind /mnt/media_rw/0711-1519 \$CHROOTFS/media/external"
}
unmount() {
  su -c "\$BB umount \$CHROOTFS/proc -lf"
  su -c "\$BB umount \$CHROOTFS/sys -lf"
  su -c "\$BB umount \$CHROOTFS/dev/shm -lf"
  su -c "\$BB umount \$CHROOTFS/dev/pts -lf"
  su -c "\$BB umount \$CHROOTFS/dev -lf"
  su -c "\$BB umount \$CHROOTFS/tmp -lf"
#  su -c "\$BB umount \$CHROOTFS/system -lf"
#  su -c "\$BB umount \$CHROOTFS/data -lf"
#  su -c "\$BB umount \$CHROOTFS/sdcard -lf"
  su -c "\$BB umount \$CHROOTFS/media/external -lf"
}
if [ -z "\$2" ]; then
  mount >/dev/null 2>&1
  echo "Entering Shell\n"
  user=root
  su -c "\$BB chroot \$CHROOTFS /bin/su - \$user"
  unmount >/dev/null 2>&1
  exit 0
else
  mount >/dev/null 2>&1
  CMD="\$2"
  user=root
  if [ "\$CMD" = "GUI" ]; then
    echo -n "\nEnter username: " && read user && user="\$user"
    run() {
      kill -9 \$(pgrep -f "termux.x11")
      XDG_RUNTIME_DIR=\${TMPDIR} termux-x11 :1 -ac & sleep 3
      pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
      pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
      MESA_NO_ERROR=1
      MESA_GL_VERSION_OVERRIDE=4.3COMPAT
      MESA_GLES_VERSION_OVERRIDE=3.2
      GALLIUM_DRIVER=zink
      ZINK_DESCRIPTORS=lazy
      virgl_test_server --use-egl-surfaceless --use-gles &
      su -c "\$BB chroot \$CHROOTFS /bin/su - \$user -c 'kill -9 \$(pgrep -f termux.x11)'"
      su -c "\$BB chroot \$CHROOTFS /bin/su - \$user -c 'pkill -f startxfce4'"
      am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity && sleep 1
      su -c "\$BB chroot \$CHROOTFS /bin/su - \$user -c 'dbus-launch --exit-with-session startxfce4'"
    }
    run >/dev/null 2>&1 &
    echo "\nLogging in shell as \$user, starting GUI in Termux:x11.\n\nType exit to quit Shell & GUI session\n"
    su -c "\$BB chroot \$CHROOTFS /bin/su - \$user"
    quit() {
      su -c "\$BB chroot \$CHROOTFS /bin/su - \$user -c 'dbus-send --session --dest=org.xfce.SessionManager --print-reply /org/xfce/SessionManager org.xfce.Session.Manager.Checkpoint string:'"
      kill -9 \$(pgrep -f virgl_test_server) >/dev/null 2>&1
      kill -9 \$(pgrep -f virglrender) >/dev/null 2>&1
      pkill -f com.termux.x11
      am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11
      unmount >/dev/null 2>&1
      exit 0
    }
    quit >/dev/null 2>&1
  fi
  su -c "\$BB chroot \$CHROOTFS /bin/su - \$user -c \$CMD"
  unmount >/dev/null 2>&1
  exit 0
fi
EOF
} > $PREFIX/bin/crsh
    chmod +x $PREFIX/bin/crsh
  }
  install_rootfs
  crsh "$OS" "/root/update.sh"
  crsh "$OS" "/root/adduser.sh"
  ascii_box "$OS has been installed!"
  echo "\nAccess Window Manager by running: crsh '$OS' GUI\n"
}

setup_"$OS"
