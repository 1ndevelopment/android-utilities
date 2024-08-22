#!/system/bin/sh

backup() {
  termux-setup-storage
  sudo tar -zcvf /sdcard/Termux-Backup.tar.gz -C /data/data/com.termux/files ./home ./usr
  prompt
}

restore() {
  termux-setup-storage
  sudo tar -zxvf /sdcard/Termux-Backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions
  chmod -R 755 /data/data/com.termux/files/usr /data/data/com.termux/files/home
  prompt
}

prompt() {
  echo -n "\nBackup or Restore Termux?\n\n1] Backup\n2] Restore\nq] Quit\n\n>>: "
  read i && echo ""
  case "$i" in
    1) backup ;;
    2) restore ;;
    q) exit 0 ;;
  esac
}

prompt
