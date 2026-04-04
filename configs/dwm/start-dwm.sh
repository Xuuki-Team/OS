#!/bin/sh
LOG=/tmp/start-dwm.log
{
  echo "== $(date) =="
  echo "DISPLAY=$DISPLAY"
  echo "XAUTHORITY=$XAUTHORITY"
  echo "PATH=$PATH"
} >> "$LOG" 2>&1

while true; do
  /usr/local/bin/dwm >> "$LOG" 2>&1
done
