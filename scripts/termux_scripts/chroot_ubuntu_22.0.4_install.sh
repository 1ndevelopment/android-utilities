
pkg update -y && pkg upgrade -y
pkg install x11-repo root-repo termux-x11-nightly tsu pulseaudio -y
pkg update -y && pkg upgrade -y

echo "allow-external-apps = true" >> ~/.termux/termux.properties && termux-reload-settings

mkdir -p /data/local/tmp/chrootubuntu
cd /data/local/tmp/chrootubuntu

curl https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-arm64.tar.gz --output ubuntu.tar.gz

tar xpvf ubuntu.tar.gz --numeric-owner

mkdir sdcard
mkdir dev/shm

sudo tee /data/local/tmp/setup_ubuntu.sh <<EOF >/dev/null
#!/bin/sh

# Assign magisk busybox
alias busybox="/data/adb/magisk/busybox"

# The path of Ubuntu rootfs
UBUNTUPATH="/data/local/tmp/chrootubuntu"

# Fix setuid issue
busybox mount -o remount,dev,suid /data

busybox mount --bind /dev \$UBUNTUPATH/dev
busybox mount --bind /sys \$UBUNTUPATH/sys
busybox mount --bind /proc \$UBUNTUPATH/proc
busybox mount -t devpts devpts \$UBUNTUPATH/dev/pts

# /dev/shm for Electron apps
busybox mount -t tmpfs -o size=256M tmpfs \$UBUNTUPATH/dev/shm

# Mount sdcard
busybox mount --bind /sdcard \$UBUNTUPATH/sdcard

# chroot into Ubuntu & install updates.
busybox chroot \$UBUNTUPATH /bin/su - root -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf \
&& echo "127.0.0.1 localhost" > /etc/hosts \
&& groupadd -g 3003 aid_inet \
&& groupadd -g 3004 aid_net_raw \
&& groupadd -g 1003 aid_graphics \
&& usermod -g 3003 -G 3003,3004 -a _apt \
&& usermod -G 3003 -a root \
&& apt update -y && apt upgrade -y \
&& apt install nano vim net-tools sudo git -y \
&& groupadd storage \
&& groupadd wheel \
&& useradd -m -g users -G wheel,audio,video,storage,aid_inet -s /bin/bash 1ndev \
&& passwd 1ndev \
&& echo "1ndev ALL=(ALL:ALL) ALL" >> /etc/sudoers \
&& exit'

busybox chroot \$UBUNTUPATH /bin/su - 1ndev -c 'sudo apt install locales -y \
&& sudo locale-gen en_US.UTF-8 \
&& sudo apt install xubuntu-desktop -y \
&& apt-get autopurge snapd '
EOF

cd /data/local/tmp/
chmod +x setup_ubuntu.sh
sudo sh setup_ubuntu.sh

sudo tee /data/local/tmp/chrootubuntu/etc/apt/preferences.d/nosnap.pref <<EOF >/dev/null
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.
# For more information: https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

sudo tee /data/local/tmp/start_ubuntu.sh <<EOF >/dev/null
#!/bin/sh

# Assign magisk busybox
alias busybox="/data/adb/magisk/busybox"

# The path of Ubuntu rootfs
UBUNTUPATH="/data/local/tmp/chrootubuntu"

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :0 -ac &
sudo busybox mount --bind $PREFIX/tmp /data/local/tmp/chrootubuntu/tmp

# Fix setuid issue
busybox mount -o remount,dev,suid /data

busybox mount --bind /dev \$UBUNTUPATH/dev
busybox mount --bind /sys \$UBUNTUPATH/sys
busybox mount --bind /proc \$UBUNTUPATH/proc
busybox mount -t devpts devpts \$UBUNTUPATH/dev/pts

# /dev/shm for Electron apps
busybox mount -t tmpfs -o size=256M tmpfs \$UBUNTUPATH/dev/shm

# Mount sdcard
busybox mount --bind /sdcard \$UBUNTUPATH/sdcard

# chroot into Ubuntu
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
busybox chroot \$UBUNTUPATH /bin/su - 1ndev -c "sudo chmod -R 777 /tmp && export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 && dbus-launch --exit-with-session startxfce4 &"
EOF

cd /data/local/tmp/
chmod +x start_ubuntu.sh
sudo sh start_ubuntu.sh
