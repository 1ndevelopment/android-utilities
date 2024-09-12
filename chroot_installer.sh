#!/system/bin/sh

source $(realpath .env)

detect_env ; root_check ; busybox_check

ROOTFS="/data/local/tmp"

init() {
  CHROOT="$ROOTFS/$OS"
}

setup_alpine() { init ;}
setup_archlinux() { init ;}
setup_artix() { init ;}
setup_debian() { init ;}
setup_debian_oldstable() { init ; OS=debian-oldstable; }
setup_deepin() { init ;}
setup_fedora() { init ;}
setup_monjaro() { init ;}
setup_openkylin() { init ;}
setup_opensuse() { init ;}
setup_pardus() { init ;}

setup_ubuntu() { init ;
  install_ubuntu() {
    mkdir -p $CHROOT/
    wget https://website.com/ -P ubuntu.tar.xz
    tar ./ubuntu.tar.xz -C $CHROOT/
    echo "$(getprop persist.sys.timezone)" > $CHROOT/etc/timezone
    echo "nameserver 8.8.8.8" > $CHROOT/etc/resolv.conf
    echo "127.0.0.1 localhost" > $CHROOT/etc/hosts
    silence mkdir -p $CHROOT/sdcard $CHROOT/system $CHROOT/data $CHROOT/media/external $CHROOT/dev/shm $CHROOT/termux
    silence chown -R media_rw:media_rw $CHROOT/media/external
    silence chmod 1777 $CHROOT/dev/shm
{
cat << EOF
#!/usr/bin/env bash
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
usermod -a -G aid_bt,aid_bt_net,aid_inet,aid_net_raw,aid_admin root
update_pkgs() { apt update -y && apt upgrade -y && apt autoremove -y ; }
update_pkgs
apt install -y sudo
sudo apt install -y git gcc build-essential cmake xfce4 xfce4-terminal dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev zenity software-properties-common mesa-utils kate fish lsd apt-transport-https vulkan-tools libegl1-mesa-dev
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
update_pkgs
exit 0
EOF
} > "$CHROOT/root/update.sh"
    chmod +x "$CHROOT/root/update.sh"
    rm -r "$CHROOT/root/adduser.sh" >/dev/null 2>&1
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
} > "$CHROOT/root/adduser.sh"
    chmod +x "$CHROOT/root/adduser.sh"
    rm -r $PREFIX/bin/crsh
{
cat << EOF
#!/system/bin/sh
[ -z "\$1" ] && echo "No OS provided.\n" && exit 0 || OS="\$1"
ROOTFS="/data/local/tmp"
CHROOT="\$ROOTFS/\$OS"
TMPDIR="/data/data/com.termux/files/usr/tmp"
BB="/data/adb/magisk/busybox"
unset LD_PRELOAD
mount() {
  su -c "\$BB mount -o remount,dev,suid /data"
  su -c "\$BB mount proc -t proc \$CHROOT/proc >/dev/null 2>&1"
  su -c "\$BB mount sys -t sysfs \$CHROOT/sys >/dev/null 2>&1"
  su -c "\$BB mount --bind /dev \$CHROOT/dev"
  su -c "\$BB mount --bind /dev/pts \$CHROOT/dev/pts"
  su -c "\$BB mount --bind \$TMPDIR \$CHROOT/tmp"
  su -c "\$BB mount -t tmpfs -o size=256M tmpfs \$CHROOT/dev/shm"
  su -c "\$BB mount --bind /system \$CHROOT/system"
  su -c "\$BB mount --bind /data \$CHROOT/data"
  su -c "\$BB mount --bind /sdcard \$CHROOT/sdcard"
  su -c "\$BB mount --bind /data/data/com.termux/files \$CHROOT/media/termux_home"
  su -c "\$BB mount --bind /mnt/media_rw/0711-1519 \$CHROOT/media/external"
}
unmount() {
  su -c "\$BB umount \$CHROOT/proc -lf"
  su -c "\$BB umount \$CHROOT/sys -lf"
  su -c "\$BB umount \$CHROOT/dev/shm -lf"
  su -c "\$BB umount \$CHROOT/dev/pts -lf"
  su -c "\$BB umount \$CHROOT/dev -lf"
  su -c "\$BB umount \$CHROOT/tmp -lf"
  su -c "\$BB umount \$CHROOT/system -lf"
  su -c "\$BB umount \$CHROOT/data -lf"
  su -c "\$BB umount \$CHROOT/sdcard -lf"
  su -c "\$BB umount \$CHROOT/media/termux_home -lf"
  su -c "\$BB umount \$CHROOT/media/external -lf"
}
if [ -z "\$2" ]; then
  mount >/dev/null 2>&1
  echo "Entering Shell\n"
  user=root
  su -c "\$BB chroot \$CHROOT /bin/su - \$user"
  unmount >/dev/null 2>&1
  exit 0
else
  mount >/dev/null 2>&1
  CMD="\$2"
  user=root
  if [ "\$CMD" = "GUI" ]; then
    echo -n "\nEnter username: " && read user && user="\$user"
    run() {
      # Kill previous termux.x11 local session just in case
      kill -9 \$(pgrep -f "termux.x11")
      # Set XDG_RUNTIME_DIR & launch termux-x11
      XDG_RUNTIME_DIR=\${TMPDIR} termux-x11 :1 -ac & sleep 3
      # Enable pulseaudio server locally
      pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
      pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
      # Set GFX variables
      MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT
      MESA_GLES_VERSION_OVERRIDE=3.2 GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy
      # Run virgl gfx server locally
      virgl_test_server --use-egl-surfaceless --use-gles &
      # Kill x11 & xfce4 within chroot
      su -c "\$BB chroot \$CHROOT /bin/su - \$user -c 'kill -9 \$(pgrep -f termux.x11)'"
      su -c "\$BB chroot \$CHROOT /bin/su - \$user -c 'pkill -f startxfce4'"
      # Finally start termux:x11 app & xfce4 as chroot user
      am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity && sleep 1
      su -c "\$BB chroot \$CHROOT /bin/su - \$user -c 'dbus-launch --exit-with-session startxfce4'"
    }
    run >/dev/null 2>&1 &
    echo "\nLogging in shell as \$user, starting GUI in Termux:x11.\n\nType exit to quit Shell & GUI session\n"
    su -c "\$BB chroot \$CHROOT /bin/su - \$user"
    quit() {
      # Logout XFCE4 x11 session
      su -c "\$BB chroot \$CHROOT /bin/su - \$user -c 'dbus-send --session --dest=org.xfce.SessionManager --print-reply /org/xfce/SessionManager org.xfce.Session.Manager.Checkpoint string:'"
      # Kill virgl gfx service
      kill -9 \$(pgrep -f virgl_test_server) >/dev/null 2>&1
      kill -9 \$(pgrep -f virglrender) >/dev/null 2>&1
      kill -9 \$(pgrep -f pulseaudio) >/dev/null 2>&1
      # Stop Termux:x11 App
      am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11
      # Kill Termux:x11 App
      pkill -f com.termux.x11
      # Unmount directories
      unmount >/dev/null 2>&1
      exit 0
    }
    quit >/dev/null 2>&1
  fi
  su -c "\$BB chroot \$CHROOT /bin/su - \$user -c \$CMD"
  unmount >/dev/null 2>&1
  exit 0
fi
EOF
} > $PREFIX/bin/crsh
    chmod +x $PREFIX/bin/crsh
  }
  install_"$OS"
  crsh "$OS" "/root/update.sh"
  crsh "$OS" "/root/adduser.sh"
  ascii_box "$OS has been installed!"
  echo "\nAccess Window Manager by running: crsh '$OS' GUI\n"
}

setup_ubuntu_oldlts() { init ; OS=ubuntu-oldlts ; }
setup_void() { init ;}

prompt() {
  ascii_box "Chroot Linux Termux:x11 Installer"
  printf "Select distro:\n\n\
1] Alpine       %s\n2] ArchLinux    %s\n3] Artix        %s\n4] Debian       %s\n\
5] Debian LTS   %s\n6] Deepin       %s\n7] Fedora       %s\n8] Monjaro      %s\n\
9] Openkylin    %s\n10] Opensuse    %s\n11] Pardus      %s\n12] Ubuntu      %s\n\
13] Ubuntu LTS  %s\n14] Void        %s\n\nq] Quit\n\n>> " \
  "$(IS alpine)" "$(IS archlinux)" "$(IS artix)" "$(IS debian)" "$(IS debian-oldstable)" \
  "$(IS deepin)" "$(IS fedora)" "$(IS monjaro)" "$(IS openkylin)" "$(IS opensuse)" \
  "$(IS pardus)" "$(IS ubuntu)" "$(IS ubuntu-oldlts)" "$(IS void)" && read -r i && echo ""
  case "$i" in
    1) OS=alpine ;; 2) OS=archlinux ;; 3) OS=artix ;; 4) OS=debian ;; 5) OS=debian_oldstable ;;
    6) OS=deepin ;; 7) OS=fedora ;; 8) OS=monjaro ;; 9) OS=openkylin ;; 10) OS=opensuse ;;
    11) OS=pardus ;; 12) OS=ubuntu ;; 13) OS=ubuntu_oldlts ;; 14) OS=void ;; q) exit 0 ;;
    *) printf "\nInvalid selection\n" && prompt ;;
  esac
  setup_"$OS"
}
prompt
