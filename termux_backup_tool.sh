#!/system/bin/sh

BIN="/system/bin"
PWD="/data/data/com.termux/files"
HOME="$PWD/home"
PREFIX="$PWD/usr"
TBIN="$PREFIX/bin"
TMP="$PREFIX/tmp"
list_name="packages.list"
packages_list="$TMP/$list_name"

. ./.env

list_installed >> "$packages_list"

backup() {
  echo "Backing up $HOME -> /sdcard/home.tar.xz\n"
  su -c "tar -cf - -C $PWD ./home | $TBIN/pv -s $(du -sb $HOME | awk '{print $1}') | $TBIN/pigz -9 > /sdcard/home.tar.xz"
  echo "\nBacking up $PREFIX -> /sdcard/usr.tar.xz\n"
  termux-backup - | pv -s $(du -sb $PREFIX | awk '{print $1}') > /storage/emulated/0/usr.tar.xz
  echo "\nCombining /sdcard/usr.tar.xz & /sdcard/home.tar.xz\ninto /sdcard/termux_backup_$timehash.tar.gz\n"
  pv /sdcard/*.tar.xz | pigz -9 > /sdcard/termux_backup_$timehash.tar.gz
  rm -r /sdcard/*.tar.xz
  ascii_box "Backup saved: /sdcard/termux_backup_$timehash.tar"
  prompt
}

restore() {
  set -- /sdcard/*.tar
  files="$@"
  [ ! -e "$1" ] && { echo "No backups found." ; prompt ; }
  ascii_box "Available backups:"
  i=0
  for file in "$@"; do
    i=$((i + 1))
    echo "$i] $file"
  done
  echo "\n\nb] Go back"
  while :; do
    echo -n "\n>> " && read choice
    [ "$choice" = b ] && prompt
    [ "$choice" = q ] && exit 0
    [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "$i" ] && { file=$(eval echo \${$choice}) ; break ; } || echo "\nInvalid choice, try again."
  done
  if [ -n "$file" ]; then
    echo "\nRestoring from $file\n"
    pv -s $(du -sb $file | awk '{print $1}') $file | tar -x -f - -C $PWD
    mv $PWD/sdcard/* $PWD && rm -r $PWD/sdcard
    $BIN/xzcat $PWD/usr.tar.xz | pv | termux-restore -
    $BIN/xzcat $PWD/home.tar.xz | pv | tar -x -C $PWD --recursive-unlink --preserve-permissions
    rm -r $PWD/*.tar.xz
    prompt
  else
    echo "No backup selected." ; restore
  fi
}

prompt() {
  ascii_box "Termux Backup Tool"
  echo -n "1] Backup\n2] Restore\n\nq] Quit\n\n>> "
  read i && echo ""
  case "$i" in
    1) backup ;; 2) restore ;; q) exit 0 ;;
  esac
}

dep_check() {
  if cmd_exists pv; then
      return
  else
      echo "Dependencies are not installed. Installing now...\n"
      silence pkg update -y && silence pkg install -y pv
      cmd_exists pv && echo "Dependencies have been successfully installed." || echo "Failed to install pv. Please try manually."
  fi
}

init() {
  dep_check
  prompt
}

#silence rm -r "$TMP"
#silence mkdir -p "$TMP"
init
