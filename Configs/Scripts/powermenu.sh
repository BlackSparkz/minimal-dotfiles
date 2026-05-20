#!/bin/bash

options="  Shutdown\n  Reboot\n  Suspend\n  Lock\n  Logout"

chosen=$(printf "$options" | fzf \
  --prompt=" Powermenu: " \
  --reverse \
  # --border \
  --no-info \
  --height=40%)

case "$chosen" in
  *Shutdown) systemctl poweroff ;;
  *Reboot)   systemctl reboot ;;
  *Suspend)  systemctl suspend ;;
  *Lock)     loginctl lock-session ;;
  *Logout)   loginctl terminate-user $USER ;;
esac
