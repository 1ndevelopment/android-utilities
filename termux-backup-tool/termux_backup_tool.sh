#!/system/bin/sh

arch() { ARCH=$(uname -m) ; [ "$ARCH" = aarch64 ] && { ARCH="arm64" && echo $ARCH ;} ; }

BIN="/system/bin"
PWD="/data/data/com.termux/files"
HOME="$PWD/home"
PREFIX="$PWD/usr"
TBIN="$PREFIX/bin"
TMP="$PREFIX/tmp"

silence() { "$@" >/dev/null 2>&1; }
sha() { sha256sum "$TMP"/"$1" | awk '{print substr($1, length($1) - 6)}' ; }
list_installed() { dpkg --get-selections | awk '{print $1}' | sed 's|/.*||' | tr '\n' ' ' | sed 's/ $/\n/' ; }

ascii_box() {
  ti="$1" ; mw=$((COLUMNS - 8)) ; bw=$mw ; b=$(printf '%*s' "$((bw-2))" | tr ' ' '=') ; pb="x${b}x" ; cw=$((bw - 6))
  echo "\n$pb\n|$(printf '%*s' "$((bw-2))")|" ; l=""
  for w in $ti; do
    if [ $((${#l} + ${#w} + 1)) -le $cw ]; then
      [ -n "$l" ] && l+=" " ; l+="$w"
    else
      p=$(( (bw - ${#l} - 2) / 2 ))
      printf "|%*s%s%*s|\n" $p "" "$l" $((bw - p - ${#l} - 2)) ""
      l="$w"
    fi
  done
  [ -n "$l" ] && { p=$(( (bw - ${#l} - 2) / 2 )) ; printf "|%*s%s%*s|\n" $p "" "$l" $((bw - p - ${#l} - 2)) "" ; }
  echo "|$(printf '%*s' "$((bw-2))")|\n$pb\n"
}

backup() {
  list_name="packages.list" ; packages_list="$TMP/$list_name" ; list_installed >> "$packages_list"
  timehash=$(echo "$(arch)_$(date +"%m-%d-%Y")_$(sha $list_name)")

  echo "Backing up $HOME -> /sdcard/home.tar.xz\n"
  su -c "tar -cf - -C $PWD ./home | $TBIN/pv -s $(du -sb $HOME | awk '{print $1}') | gzip > /sdcard/home.tar.xz"

  echo "\nBacking up $PREFIX -> /sdcard/usr.tar.xz\n"
  termux-backup - | pv -s $(du -sb "$PREFIX" | awk '{print $1}') > /sdcard/usr.tar.xz

  echo "\nCombining usr.tar.xz & home.tar.xz into termux_backup.$timehash.tar\n"
  tar -cf - /sdcard/*.tar.xz | pv -s $(du -sb /sdcard/*.tar.xz | awk '{print $1}' | awk '{sum += $1} END {print sum}' | /system/bin/bc) > /sdcard/termux_backup.$timehash.tar

  rm -r /sdcard/*.tar.xz

  ascii_box "Backup saved: /sdcard/termux_backup.$timehash.tar"
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
  command_exists() { command -v "$1" >/dev/null 2>&1 ; }
  if command_exists pv; then
      return
  else
      echo "Dependencies are not installed. Installing now...\n"
      silence pkg update -y && silence pkg install -y pv
      command_exists pv && echo "Dependencies have been successfully installed." || echo "Failed to install pv. Please try manually."
  fi
}

init() {
  dep_check
  prompt
}

silence rm -r "$TMP" && silence mkdir -p "$TMP"
init
