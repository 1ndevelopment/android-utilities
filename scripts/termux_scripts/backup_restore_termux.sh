#!/system/bin/sh

backup() {
  if [ -d "~/storage" ]; then
    termux-setup-storage
    backup
  else
    cd ../..
    sudo tar cvzf /sdcard/Termux-Backup.tgz ./
    prompt
  fi
}

restore() {
  if [ -d "~/storage" ]; then
    termux-setup-storage
    restore
  else
    cd ../..
    sudo tar xvzf /sdcard/Termux-Backup.tgz
    prompt
  fi
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
