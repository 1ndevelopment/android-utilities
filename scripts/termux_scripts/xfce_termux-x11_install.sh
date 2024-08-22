
installdeps() {
yes | pkg upgrade
echo "allow-external-apps = true" >> ~/.termux/termux.properties && termux-reload-settings
pkg install x11-repo tur-repo && pkg install termux-x11-nightly xwayland -y
pkg install xfce4 -y
echo -n "\nInstall Code , Firefox & VLC?\n[y/n]: " && read i
[ "$i" = y ] && { pkg install code-oss code-is-code-oss firefox vlc-qt -y ; }
pkg install mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android glmark2 -y

rm -r $PREFIX/share/fonts/0xProto
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/0xProto.zip -P $PREFIX/share/fonts && unzip $PREFIX/share/fonts/0xProto.zip -d $PREFIX/share/fonts/0xProto/ && rm $PREFIX/share/fonts/0xProto.zip
}

placexec() {

rm $PREFIX/bin/start-termux-x11

cat << 'EOF' > $PREFIX/bin/start-termux-x11
echo ""
echo "Be sure to logout of xfce in x11 before ending this command"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
(MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server_android --use-egl-surfaceless --use-gles & termux-x11 :1 -xstartup "dbus-launch --exit-with-session xfce4-session")
virgl_server_pid=$(ps | grep virglrenderer-android | awk '{ print $1 }')
wait
kill $virgl_server_pid
EOF

chmod +x $PREFIX/bin/start-termux-x11

endprompt
}

run() {
start-termux-x11
}

endprompt() {
echo ""
echo "To start Termux in Desktop Mode simply run the command:"
echo ""
echo "start-termux-x11"
echo ""
}

prompt() {
echo ""
echo "TERMUX X11 XFCE INSTALLER"
echo ""
}

prompt
installdeps
placexec

# GALLIUM_DRIVER=zink MESA_GL_VERSION_OVERRIDE=4.3COMPAT glmark2
