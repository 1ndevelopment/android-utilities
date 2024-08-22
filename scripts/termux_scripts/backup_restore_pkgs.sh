#!/system/bin/sh

backup_dir="/sdcard/termux_pkgs"

silence() { "$@" >/dev/null 2>&1; }
sha() { sha256sum "$backup_dir"/"$1" | awk '{print substr($1, length($1) - 6)}' ; }
list_installed() { dpkg --get-selections | awk '{print $1}' | sed 's|/.*||' | tr '\n' ' ' | sed 's/ $/\n/' ; }

ascii_box() {
  ti="$1" ; mw=$((COLUMNS - 8)) ; bw=$mw
  b=$(printf '%*s' "$((bw-2))" | tr ' ' '=')
  pb="x${b}x" ; cw=$((bw - 6))
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
  list_installed >> "$backup_dir"/.tmp
  list_name=$(echo "packages.$(date +"%m-%d-%Y").$(sha .tmp).list")
  packages_list="$backup_dir/$list_name"
  list_installed >> "$packages_list"
  ascii_box "Backup saved: $list_name"
  prompt
}

restore() {
  set -- "$backup_dir"/*.list
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
  [ -n "$file" ] && { command="pkg install $(cat "$file")" ; echo "\nRestoring from $file\n" ; $command ; prompt ; } || echo "No backup selected." ; restore
}

cleanup() {
  rm -r $backup_dir
  ascii_box "Removed package lists from $backup_dir"
  silence mkdir -p "$backup_dir"
  prompt
}

prompt() {
  ascii_box "Generate Termux Packages List"
  echo -n "1] Backup\n2] Restore\n3] Cleanup\nq] Quit\n\n>> "
  read i && echo ""
  case "$i" in
    1) backup ;; 2) restore ;; 3) cleanup ;; q) exit 0 ;;
  esac
}

silence mkdir -p "$backup_dir"
prompt
