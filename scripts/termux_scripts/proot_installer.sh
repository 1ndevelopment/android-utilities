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

  echo -n "\nInput username: " && read user && echo ""

  login() {
    if [ -f "$ROOTFS/home/$user/.local/start-xfce-x11.sh" ]; then
      if [ -f "$PREFIX/bin/run-$OS-x11" ]; then
        run-$OS-x11
      else
{
cat << EOF
pdsh() { x="\$1" ; pd sh "$OS" --shared-tmp --no-sysvipc -- env DISPLAY=:1 \$x ; }
kill -9 \$(pgrep -f "termux.x11") 2>/dev/null
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :1 -ac >/dev/null & sleep 3
#am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1

MESA_NO_ERROR=1
MESA_GL_VERSION_OVERRIDE=4.3COMPAT
MESA_GLES_VERSION_OVERRIDE=3.2
GALLIUM_DRIVER=zink
ZINK_DESCRIPTORS=lazy
virgl_test_server --use-egl-surfaceless --use-gles &

pdsh "kill -9 \$(pgrep -f termux.x11)" > /dev/null 2>&1
pdsh "PULSE_SERVER=127.0.0.1" > /dev/null 2>&1
pdsh "XDG_RUNTIME_DIR=${TMPDIR}" > /dev/null 2>&1

if grep TERMUX_HOME /etc/environment; then
  
else
  echo "TERMUX_HOME=$HOME" >> "$ROOTFS"/etc/environment
fi

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1
pdsh "./../home/$user/.local/start-xfce-x11.sh"
pkill virgl_test_server && pkill virglrender
exit 0
EOF
} >> $PREFIX/bin/run-$OS-x11
        chmod +x $PREFIX/bin/run-$OS-x11
        login
      fi
    else
      echo "su - $user -c \"termux-x11 :1 -xstartup 'dbus-launch --exit-with-session xfce4-session'\"" >> "$ROOTFS"/home/"$user"/.local/start-xfce-x11.sh
      chmod +x "$ROOTFS"/home/"$user"/.local/start-xfce-x11.sh
      login
    fi
  }
  install_pkgs() {
    echo "apt install sudo -y" >> "$ROOTFS"/root/update.sh
    echo "sudo apt install xfce4 xfce4-terminal dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev -y" >> "$ROOTFS"/root/update.sh
    echo "update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50" >> "$ROOTFS"/root/update.sh
    echo "update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal" >> "$ROOTFS"/root/update.sh
    chmod +x "$ROOTFS"/root/update.sh && pdsh "./update.sh"
  }
  adduser() {
    rm -r "$ROOTFS"/root/adduser.sh >/dev/null 2>&1
    echo -n "\nInput password: " && read pass
    echo "groupadd storage && groupadd wheel" >> "$ROOTFS"/root/adduser.sh
    echo "useradd -m -g users -G wheel,audio,video,storage -s /bin/bash $user" >> "$ROOTFS"/root/adduser.sh
    echo "echo "$user:$pass" | chpasswd" >> "$ROOTFS"/root/adduser.sh
    chmod +x "$ROOTFS"/root/adduser.sh
    pdsh "./adduser.sh"
    chmod u+rw "$ROOTFS"/etc/sudoers
    echo "$user ALL=(ALL) ALL" >> "$ROOTFS"/etc/sudoers
    chmod u-w "$ROOTFS"/etc/sudoers
  }

  prep() {
    if [ -f "$ROOTFS/root/update.sh" ]; then
      [ "$user" = android ] && login || adduser ; setup_"$OS"
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

