#!/system/bin/sh

OS="$1"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/$OS"

cmd_exists() { command -v "$1" >/dev/null 2>&1 ; }
pdsh() { x="$1" ; pd sh "$OS" --shared-tmp --no-sysvipc -- env DISPLAY=:1 $x ; }
check() { [ -d "$ROOTFS" ] && return || pd i "$OS" && termux-reload-settings ; }
timezone() { [ -f "$ROOTFS/etc/timezone" ] && return || echo "$(getprop persist.sys.timezone)" > $ROOTFS/etc/timezone ; }
update_pkgs() { pdsh "apt update -y" && pdsh "apt upgrade -y" && pdsh "apt autoremove -y" ; }


init() { check ; timezone ; } #update_pkgs ; }

setup_alpine() { init ;}
setup_archlinux() { init ;}
setup_artix() { init ;}
setup_debian() { init ;}
setup_debian-oldstable() { init ;}
setup_deepin() { init ;}
setup_fedora() { init ;}
setup_monjaro() { init ;}
setup_openkylin() { init ;}
setup_opensuse() { init ;}
setup_pardus() { init ;}


setup_ubuntu() { init ;

  login() {
    if [ -f "$ROOTFS/usr/local/bin/start-xfce-x11" ]; then
      if [ -f "$PREFIX/bin/run-$OS-x11" ]; then
        run-$OS-x11 $user
      else
{
cat << EOF
#!/system/bin/sh
[ -z "\$1" ] && { user="? username" ; } || user="\$1"
pdsh() { x="\$1" ; pd sh "$OS" --shared-tmp --no-sysvipc -- env DISPLAY=:1 \$x ; }
idc() { pdsh "id \$user" >/dev/null 2>&1 ; }
! idc && { echo "\n\$user does not exist, try again." && exit 0 ;} || echo "\nLogging in as \$user"
kill -9 \$(pgrep -f "termux.x11") 2>/dev/null
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :1 -ac >/dev/null & sleep 3
MESA_NO_ERROR=1
MESA_GL_VERSION_OVERRIDE=4.3COMPAT
MESA_GLES_VERSION_OVERRIDE=3.2
GALLIUM_DRIVER=zink
ZINK_DESCRIPTORS=lazy
virgl_test_server --use-egl-surfaceless --use-gles &
pdsh "kill -9 \$(pgrep -f termux.x11)" > /dev/null 2>&1
run() {
  if grep -q TERMUX_HOME $ROOTFS/etc/environment; then
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1
    pdsh "/usr/local/bin/start-xfce-x11" > /dev/null 2>&1
    pkill virgl_test_server && pkill virglrender
  else
    echo "XDG_RUNTIME_DIR=${TMPDIR}" >> $ROOTFS/etc/environment
    if grep -q GALLIUM_DRIVER $ROOTFS/home/\$user/.bashrc; then
      echo "TERMUX_HOME=$HOME" >> $ROOTFS/etc/environment
    else
      echo "export GALLIUM_DRIVER=zink" >> $ROOTFS/home/\$user/.bashrc
    fi
    run
  fi
}
run
exit 0
EOF
} >> $PREFIX/bin/run-$OS-x11
        chmod +x $PREFIX/bin/run-$OS-x11 && login
      fi
    else
      echo "su - $user -c \"termux-x11 :1 -xstartup 'dbus-launch --exit-with-session xfce4-session'\"" >> "$ROOTFS"/usr/local/bin/start-xfce-x11
      chmod +x "$ROOTFS"/usr/local/bin/start-xfce-x11 && login
    fi
  }

  install_pkgs() {
    rm -r "$ROOTFS"/root/update.sh
{
cat << EOF
#!/usr/bin/env bash
apt install sudo -y
sudo apt install xfce4 xfce4-terminal dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev -y
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
exit 0
EOF
} >> "$ROOTFS"/root/update.sh
    chmod +x "$ROOTFS"/root/update.sh && pdsh "./update.sh"
  }

  adduser() {
    rm -r "$ROOTFS"/root/adduser.sh >/dev/null 2>&1
{
cat << EOF
#!/usr/bin/env bash
[ -n "\$user" ] && { echo "..."; } || echo -n "Username: " && read user
! id \$user >/dev/null 2>&1 && {
  echo -n "Password: " && read pass && echo ''
  groupadd storage && groupadd wheel
  useradd -m -g users -G wheel,audio,video,storage -s /bin/bash \$user
  echo "\$user:\$pass" | chpasswd
  chmod u+rw /etc/sudoers
  echo "\$user ALL=(ALL) ALL" >> /etc/sudoers
  chmod u-w /etc/sudoers
  echo "\$user" >> /root/.tmp
exit 0
} || echo "\$user" >> /root/.tmp
EOF
} >> "$ROOTFS"/root/adduser.sh
    chmod +x "$ROOTFS"/root/adduser.sh
    pdsh "./adduser.sh"
  }

  prep() {
    if [ -f "$ROOTFS/root/update.sh" ]; then
      [ -e "$ROOTFS/root/.tmp" ] && { user=$(cat "$ROOTFS"/root/.tmp) ; login ; }
      user="?"
      idc() { pdsh "id $user" >/dev/null 2>&1 ; }
      ! idc && { adduser ; setup_"$OS" ; }
    else
      install_pkgs
      prep
    fi
  }
  prep

}


setup_ubuntu-oldlts() { init ;}
setup_void() { init ;}

dep_check() {
  if cmd_exists proot-distro; then
    [ "$OS" = alpine ] && setup_"$OS"
    [ "$OS" = archlinux ] && setup_"$OS"
    [ "$OS" = artix ] && setup_"$OS"
    [ "$OS" = debian ] && setup_"$OS"
    [ "$OS" = debian-oldstable ] && setup_"$OS"
    [ "$OS" = deepin ] && setup_"$OS"
    [ "$OS" = fedora ] && setup_"$OS"
    [ "$OS" = monjaro ] && setup_"$OS"
    [ "$OS" = openkylin ] && setup_"$OS"
    [ "$OS" = opensuse ] && setup_"$OS"
    [ "$OS" = pardus ] && setup_"$OS"
    [ "$OS" = ubuntu ] && setup_"$OS"
    [ "$OS" = ubuntu-oldlts ] && setup_"$OS"
    [ "$OS" = void ] && setup_"$OS"
  else
    pkg install x11-repo -y && pkg update && termux-setup-storage
    pkg install dbus proot proot-distro pulseaudio virglrenderer-android pavucontrol-qt mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android glmark2 mesa-zink virglrenderer-mesa-zink -y
    printf "OS=\$1\npdsh() { x=\"\$1\" ; pd sh \"\$OS\" --shared-tmp --no-sysvipc -- env DISPLAY=:1 \$x ; }\n[ -n \"\$2\" ] && { pdsh \$2 ; exit 0 ;} || pdsh /bin/bash ; exit 0\n" >> $PREFIX/bin/pdsh && chmod +x $PREFIX/bin/pdsh
  fi
}

dep_check

