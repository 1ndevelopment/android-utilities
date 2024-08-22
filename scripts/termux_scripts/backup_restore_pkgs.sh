#!/system/bin/sh

ascii_box() {
  text_input="$1" ; max_width=$((COLUMNS - 8)) ; box_width=$max_width
  border=$(printf '%*s' "$((box_width-2))" | tr ' ' '=')
  print_border="x${border}x" ; content_width=$((box_width - 6))
  # Print the top of the box
  echo "$print_border\n|$(printf '%*s' "$((box_width-2))")|" ; line=""
  for words in $text_input; do
    if [ $((${#line} + ${#words} + 1)) -le $content_width ]; then
      [ -n "$line" ] && line+=" " ; line+="$words"
    else
      # Print the current line
      padding=$(( (box_width - ${#line} - 2) / 2 ))
      printf "|%*s%s%*s|\n" $padding "" "$line" $((box_width - padding - ${#line} - 2)) ""
      line="$words"
    fi
  done
  # Print the last line if there's any content left
  [ -n "$line" ] && { padding=$(( (box_width - ${#line} - 2) / 2 )) ; printf "|%*s%s%*s|\n" $padding "" "$line" $((box_width - padding - ${#line} - 2)) "" ; }
  echo "|$(printf '%*s' "$((box_width-2))")|\n$print_border"
}

silence() { "$@" >/dev/null 2>&1; }
list_installed() { dpkg --get-selections | awk '{print $1}' | sed 's|/.*||' | tr '\n' ' ' | sed 's/ $/\n/' ; }
packages_list="/data/data/com.termux/files/packages.list"

backup() {
  silence rm "$packages_list" && touch "$packages_list"
  list_installed >> $packages_list && echo "$(list_installed)"
#  termux-setup-storage
#  sudo tar -zcvf /sdcard/Termux-Backup.tar.gz -C /data/data/com.termux/files ./home ./usr
  prompt
}

restore() {
  command="pkg install $(cat "$packages_list") -y" && echo $command
#  termux-setup-storage
#  sudo tar -zxvf /sdcard/Termux-Backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions
#  chmod -R 755 /data/data/com.termux/files/usr /data/data/com.termux/files/home
  prompt
}

prompt() {
  echo "" && ascii_box "Backup & Restore Termux Packages"
  echo -n "\n1] Backup\n2] Restore\nq] Quit\n\n>> "
  read i && echo ""
  case "$i" in
    1) backup ;;
    2) restore ;;
    q) exit 0 ;;
  esac
}
prompt
