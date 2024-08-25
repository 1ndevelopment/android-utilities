#!/system/bin/sh

#
# Script Name: Proot Linux Termux:x11 Installer
# Author: Jacy Kincade (1ndevelopment@protonmail.com)
#
# License: GPL
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.
#
# Description: Install Linux distro ontop of Termux:x11
#

. ./.env

ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs"

init() {
  PROOT="$ROOTFS/$OS"
  check ; timezone ; update_pkgs
}

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
    if [ -f "$PROOT/usr/local/bin/start-xfce-x11" ]; then
      if [ -f "$PREFIX/bin/run-$OS-x11" ]; then
        ascii_box "$OS has successfully been installed!"
        echo "To launch, simply run: run-ubuntu-x11 $user\n"
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
  if grep -q TERMUX_HOME $PROOT/etc/environment; then
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1
    pdsh "/usr/local/bin/start-xfce-x11" > /dev/null 2>&1
    pkill virgl_test_server && pkill virglrender
  else
    echo "XDG_RUNTIME_DIR=${TMPDIR}" >> $PROOT/etc/environment
    if grep -q GALLIUM_DRIVER $PROOT/home/\$user/.bashrc; then
      echo "TERMUX_HOME=$HOME" >> $PROOT/etc/environment
    else
      echo "export GALLIUM_DRIVER=zink" >> $PROOT/home/\$user/.bashrc
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
      echo "su - $user -c \"termux-x11 :1 -xstartup 'dbus-launch --exit-with-session xfce4-session'\"" >> "$PROOT"/usr/local/bin/start-xfce-x11
      chmod +x "$PROOT"/usr/local/bin/start-xfce-x11 && login
    fi
  }

  install_pkgs() {
    rm -r "$PROOT"/root/update.sh
{
cat << EOF
#!/usr/bin/env bash
apt install sudo -y
sudo apt install xfce4 xfce4-terminal dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev -y
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
install_ohmyzsh
exit 0
EOF
} >> "$PROOT"/root/update.sh
    chmod +x "$PROOT"/root/update.sh && pdsh "./update.sh"
  }

  adduser() {
    rm -r "$PROOT"/root/adduser.sh >/dev/null 2>&1
{
cat << EOF
#!/usr/bin/env bash
[ -n "\$user" ] && { echo "..."; } || echo "" && echo -n "Enter Username: " && read user
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
} >> "$PROOT"/root/adduser.sh
    chmod +x "$PROOT"/root/adduser.sh
    pdsh "./adduser.sh"
  }

  prep() {
    if [ -f "$PROOT/root/update.sh" ]; then
      [ -e "$PROOT/root/.tmp" ] && { user=$(cat "$PROOT"/root/.tmp) ; login ; }
      user="?"
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

prompt() {
  if cmd_exists proot-distro; then
    ascii_box "Proot Linux Termux:x11 Installer"
    echo -n "Select distro:\n\n1] Alpine       $(IS alpine)\n2] ArchLinux    $(IS archlinux)\n3] Artix        $(IS artix)\n4] Debian       $(IS debian)\n5] Debian LTS   $(IS debian-oldstable)\n6] Deepin       $(IS deepin)\n7] Fedora       $(IS fedora)\n8] Monjaro      $(IS monjaro)\n9] Openkylin    $(IS openkylin)\n10] Opensuse    $(IS opensuse)\n11] Pardus      $(IS pardus)\n12] Ubuntu      $(IS ubuntu)\n13] Ubuntu LTS  $(IS ubuntu-oldlts)\n14] Void        $(IS void)\n\nq] Quit\n\n>> "
    read i
    case "$i" in
      1) OS=alpine ;; 2) OS=archlinux ;; 3) OS=artix ;;
      4) OS=debian ;; 5) OS=debian-oldstable ;; 6) OS=deepin ;;
      7) OS=fedora ;; 8) OS=monjaro ;; 9) OS=openkylin ;;
      10) OS=opensuse ;; 11) OS=pardus ;; 12) OS=ubuntu ;;
      13) OS=ubuntu-oldlts ;; 14) OS=void ;; q) exit 0 ;;
      *) echo "\nInvalid selection\n" && prompt ;;
    esac
    setup_"$OS"
  else
    wget $(curl -s https://api.github.com/repos/termux/termux-x11/actions/artifacts | grep -oP 'https://.+?termux-x11.+?\.apk' | head -n 1) -O /sdcard/termux-x11-latest.apk
    am start -a android.intent.action.VIEW -d file:///sdcard/termux-x11-latest.apk && rm /sdcard/termux-x11-latest.apk
    ascii_box "Installing needed packages..."
    pkg install x11-repo termux-x11-repo -y && pkg update && termux-setup-storage
    pkg install dbus proot proot-distro pulseaudio virglrenderer-android pavucontrol-qt mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android glmark2 mesa-zink virglrenderer-mesa-zink xkeyboard-config termux-am cabextract -y
    printf "OS=\$1\npdsh() { x=\"\$1\" ; pd sh \"\$OS\" --shared-tmp --no-sysvipc -- env DISPLAY=:1 \$x ; }\n[ -n \"\$2\" ] && { pdsh \$2 ; exit 0 ;} || pdsh /bin/bash ; exit 0\n" >> $PREFIX/bin/pdsh && chmod +x $PREFIX/bin/pdsh
    prompt
  fi
}
prompt
