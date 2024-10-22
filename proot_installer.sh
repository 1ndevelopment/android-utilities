#!/system/bin/sh

#
# Script Name: Proot-Distro Termux:x11 Installer
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
# Fully cleanup post install files & directories
# rm "$PREFIX/bin/run-ubuntu-x11" "$PROOT/tmp/chsh_fish" "$PROOT/tmp/.tmp" "$PREFIX/tmp/install_ohmyzsh.sh" "$PREFIX/tmp/install_wine.sh" "$PROOT/usr/local/bin/start-xfce-x11" "$PROOT/tmp/update.sh" "$PROOT/root/adduser.sh" "$PREFIX/tmp/adduser.sh" "$PROOT/tmp/chsh_fish.sh" "$PROOT/tmp/chsh-fish.sh" "$PROOT/root/.active_user" >/dev/null 2>&1 && nano "$PROOT/etc/environment" && nano "$PROOT/home/$user/.config/fish/config.fish"
#

source $(realpath .env)

ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs"

init() { export PROOT="$ROOTFS/$OS" ;}

setup_alpine() { init ;
  ins_deps() {
    ## Install proot-distro & dependencies
    pkg install -y x11-repo tur-repo && pkg update && termux-setup-storage 
    pkg install -y dbus proot proot-distro pulseaudio virglrenderer-android pavucontrol-qt mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android glmark2 mesa-zink virglrenderer-mesa-zink xkeyboard-config termux-am cabextract
  }
  init_config() {
    pdsh() { proot-distro login alpine --shared-tmp -- /bin/ash -c "$1" ;}
    update_pkgs() { pdsh "apk update && apk upgrade" ;}
    install_setup_pkgs() { pdsh "apk add sudo nano dbus-x11 xfce chromium fish" ;}
  
    add_user() { 
      printf "Username: " && read username && printf ""
      pdsh "adduser $username && adduser $username wheel && echo '$username All=(ALL:ALL) ALL' >> /etc/sudoers" ;}

    ## Create alpine launcher for termux (example: run-alpine-x11 your-username)
{
cat << EOF
#!/data/data/com.termux/files/usr/bin/bash
printf "Username: " && read username && printf ""
pdsh() { proot-distro login alpine --user \$username --shared-tmp -- /bin/ash -c "\$1" ;}
kill -9 \$(pgrep -f "termux.x11") 2>/dev/null
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
export XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :0 >/dev/null &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1
pdsh 'export PULSE_SERVER=127.0.0.1 && export XDG_RUNTIME_DIR=\${TMPDIR} && env DISPLAY=:0 startxfce4'
exit 0
EOF
} > "$PREFIX/bin/run-alpine-x11" && chmod +x "$PREFIX/bin/run-alpine-x11"
  }
  # Determine if OS is installed, if not then init, configure & setup
  if [ -d "$PROOT" ]; then
    echo "$OS is installed."
    run-alpine-x11
  else
    ins_deps
    pd i "$OS"
    termux-reload-settings
    init_config
  fi
}

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
  ins_deps() {
    ## Install proot-distro & dependencies
    pkg install -y x11-repo tur-repo && pkg update && termux-setup-storage 
    pkg install -y dbus proot proot-distro pulseaudio virglrenderer-android pavucontrol-qt mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android glmark2 mesa-zink virglrenderer-mesa-zink xkeyboard-config termux-am cabextract
  }
  init_config() {
    ## Set timezone
    [ -f "$PROOT/etc/timezone" ] && { echo "Updated timezone to: $(cat $PROOT/etc/timezone)" ;} || echo "$(getprop persist.sys.timezone)" > "$PROOT/etc/timezone"
    ## Disable snap pkgs
{
cat << EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
} > "$PROOT/etc/apt/preferences.d/nosnap.pref"
    ## Configure environment variables
    echo "XDG_RUNTIME_DIR=${TMPDIR}" >> "$PROOT/etc/environment"
    ## Update and install essential dependencies
{
cat << EOF
#!/usr/bin/env bash
update_pkgs() { apt update -y && apt upgrade -y && apt autoremove -y ; }
update_pkgs
apt install -y sudo
sudo apt install -y git gcc build-essential cmake xfce4 xfce4-terminal terminator dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev zenity software-properties-common mesa-utils fish lsd
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
update_pkgs
exit 0
EOF
} > "$PROOT/root/update.sh" && chmod +x "$PROOT/root/update.sh"
    $PREFIX/bin/pdsh "$OS" "root" "$PROOT/root/update.sh"
    ## Create adduser.sh script
{
cat << EOF
#!/usr/bin/env bash
func() {
  [ -n "\$user" ] && { printf "..." ; } || printf "\nEnter Username: " && read user && printf ""
  if awk -F":" '{print \$1}' /etc/passwd | grep -q "\$user"; then
    printf "\nLogging in as \$user\n"
    echo "\$user" > "/root/.active_user"
  else
    printf "Password: " && read pass && printf ""
    groupadd storage && groupadd wheel
    useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "\$user"
    printf "%s:%s" "\$user" "\$pass" | chpasswd
    chmod u+rw /etc/sudoers
    printf "%s ALL=(ALL) ALL\n" "\$user" >> /etc/sudoers
    chmod u-w /etc/sudoers
    printf "\n\$user has been created!\n"
    exit 0
  fi
}
func
EOF
} > "$PROOT/root/adduser.sh" && chmod +x "$PROOT/root/adduser.sh"
    $PREFIX/bin/pdsh "$OS" "root" "$PROOT/root/adduser.sh"
    ## Create launcher for termux
{
cat << EOF
#!/data/data/com.termux/files/usr/bin/sh
printf "Username: " && read user && printf ""
killall -9 termux-x11 Xwayland pulseaudio virgl_test_server virgl_test_server_android termux-wake-lock > /dev/null 2>&1
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :1 -ac &
sleep 3
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
#MESA_NO_ERROR=1
#MESA_GL_VERSION_OVERRIDE=4.3COMPAT
#MESA_GLES_VERSION_OVERRIDE=3.2
#ZINK_DESCRIPTORS=lazy
GALLIUM_DRIVER=zink
virgl_test_server --use-egl-surfaceless --use-gles &
proot-distro login ubuntu --user \$user --shared-tmp -- bash -c "export DISPLAY=:1 PULSE_SERVER=tcp:127.0.0.1 ; dbus-launch --exit-with-session startxfce4" > /dev/null 2>&1
echo "Shutting down instance..."
pkill -9 -f "virgl_test_server|virgl_test_server_android|virglrender|pulseaudio" > /dev/null 2>&1
exit 0
EOF
} > "$PREFIX/bin/run-ubuntu-x11" && chmod +x "$PREFIX/bin/run-ubuntu-x11"
  }
  ## Determine if OS is installed, if not then init, configure & setup
  if [ -d "$PROOT" ]; then
    echo "$OS is installed."
    run-ubuntu-x11
  else
    ins_deps
    pd i "$OS"
    termux-reload-settings
    init_config
  fi
}

setup_ubuntu_old() { init ;
  login() {
    user=$(cat "$PROOT/root/.active_user")
    if [ -f "$PROOT/usr/local/bin/start-xfce-x11" ]; then
      if [ -f "$PREFIX/bin/run-$OS-x11" ]; then

        ## post install selection, add any additional commands below:
        install_gles
        ## END

        ascii_box "$OS has successfully been installed!"
        printf "To launch a root shell, run: pdsh %s\nTo launch into GUI, simply run: run-%s-x11 %s\n" "$OS" "$OS" "$user"
      else
        run() {
          if grep -q PROOT "$PROOT/etc/environment"; then
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
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1
run() {
  pdsh "/usr/local/bin/start-xfce-x11" > /dev/null 2>&1
  pkill virgl_test_server /dev/null 2>&1
  pkill virglrender /dev/null 2>&1
}
run &
exit 0
EOF
} >> "$PREFIX/bin/run-$OS-x11"
            chmod +x "$PREFIX/bin/run-$OS-x11"
            login
          else
            if grep -q GALLIUM_DRIVER "$PROOT/home/$user/.config/fish/config.fish"; then
              printf "XDG_RUNTIME_DIR=%s\nTERMUX_HOME=%s\nPROOT=%s\n" "$TMPDIR" "$HOME" "$PROOT" >> "$PROOT/etc/environment"
              run
            else
              sed -i "3i export GALLIUM_DRIVER=zink" "$PROOT/home/$user/.config/fish/config.fish"
              sed -i "4i alias ls='lsd -1A'" "$PROOT/home/$user/.config/fish/config.fish"
              sed -i "5i echo '' && fastfetch --logo none && echo '' && cal" "$PROOT/home/$user/.config/fish/config.fish"
              chsh_fish() {
                echo -e "su - \$user -c \"[ '\$(getent passwd \$USER | cut -d: -f7)' != '/usr/bin/fish' ] && { chsh -s '/usr/bin/fish' ;} || echo -e 'Using fish'\"\n" > "$PROOT/root/fishy.sh" && chmod +x "$PROOT/root/fishy.sh"
                chmod +x "$PROOT/root/fishy.sh" && pdsh "/root/fishy.sh"
                rm "$PROOT/root/fishy.sh" >/dev/null 2>&1
              }
              chsh_fish
              run
            fi
            run
          fi
        }
        run
      fi
    else
      printf "su - %s -c \"termux-x11 :1 -xstartup 'dbus-launch --exit-with-session xfce4-session'\"\n" "$user" > "$PROOT/usr/local/bin/start-xfce-x11"
      chmod +x "$PROOT/usr/local/bin/start-xfce-x11" && login
    fi
  }
  install_pkgs() {
    rm -r "$PROOT/tmp/update.sh" >/dev/null 2>&1
{
cat << EOF
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.
# For more information: https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
} > "$PROOT/etc/apt/preferences.d/nosnap.pref"
{
cat << EOF
#!/usr/bin/env bash
update_pkgs() { apt update -y && apt upgrade -y && apt autoremove -y ; }
update_pkgs
apt install -y sudo
sudo apt install -y git gcc build-essential cmake xfce4 xfce4-terminal dbus-x11 wget apt-utils locales-all dialog tzdata libglvnd-dev zenity software-properties-common mesa-utils kate fish lsd
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
update_pkgs
exit 0
EOF
} > "$PROOT/root/update.sh"
    chmod +x "$PROOT/root/update.sh"
  ## pdsh "./update.sh"
    mv "$PROOT/root/update.sh" "$PROOT/tmp/update.sh"
  }
  adduser() {
    rm -r "$PROOT/root/adduser.sh" >/dev/null 2>&1
{
cat << EOF
#!/usr/bin/env bash
func() {
  [ -n "\$user" ] && { printf "..." ; } || printf "\nEnter Username: " && read user && printf ""
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
} > "$PROOT/root/adduser.sh"
    chmod +x "$PROOT/root/adduser.sh"
    pdsh "./adduser.sh"
  }
  prep() {
    if [ -f "$PROOT/tmp/update.sh" ]; then
      adduser
    else
      install_pkgs
      prep
    fi
    login
  }
  prep
}
setup_ubuntu_oldlts() { init ; OS=ubuntu-oldlts ; }
setup_void() { init ;}

prompt() {
  if cmd_exists proot-distro; then
    ascii_box "Proot Linux Termux:x11 Installer"
    printf "Select distro:\n\n\
1] Alpine       %s\n\
2] ArchLinux    %s\n\
3] Artix        %s\n\
4] Debian       %s\n\
5] Debian LTS   %s\n\
6] Deepin       %s\n\
7] Fedora       %s\n\
8] Monjaro      %s\n\
9] Openkylin    %s\n\
10] Opensuse    %s\n\
11] Pardus      %s\n\
12] Ubuntu      %s\n\
13] Ubuntu LTS  %s\n\
14] Void        %s\n\n\
q] Quit\n\n>> " \
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
  else
    wget "$(curl -s https://api.github.com/repos/termux/termux-x11/actions/artifacts | grep -oP 'https://.+?termux-x11.+?\.apk' | head -n 1)" -O /sdcard/termux-x11-latest.apk
    am start -a android.intent.action.VIEW -d file:///sdcard/termux-x11-latest.apk && rm /sdcard/termux-x11-latest.apk
    ascii_box "Installing needed packages..."
    pkg install x11-repo termux-x11-repo -y && pkg update && termux-setup-storage
    pkg install dbus proot proot-distro pulseaudio virglrenderer-android pavucontrol-qt mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android glmark2 mesa-zink virglrenderer-mesa-zink xkeyboard-config termux-am cabextract -y
    printf "OS=\$1\npdsh() { x=\"\$1\" ; pd sh \"\$OS\" --shared-tmp --no-sysvipc -- env DISPLAY=:1 \$x ; }\n[ -n \"\$2\" ] && { pdsh \$2 ; exit 0 ;} || pdsh /bin/bash ; exit 0\n" > "$PREFIX/bin/pdsh" && chmod +x "$PREFIX/bin/pdsh"
    prompt
  fi
}
prompt
