#!/bin/bash

LOG="$HOME/logs/cleanup-monthly.log"
mkdir -p "$(dirname "$LOG")"

echo "===== $(date) [MONTHLY CLEANUP START] =====" >> "$LOG"

# Clear all logs
echo "[START] Clearing all system logs..." >> "$LOG"
rm -rf ~/Library/Logs/* \
  && echo "[DONE] System logs cleared" >> "$LOG" \
  || echo "[ERROR] Log reset failed" >> "$LOG"

# Xcode simulator cleanup
if command -v xcrun >/dev/null; then
  echo "[START] Cleaning Xcode simulators..." >> "$LOG"
  xcrun simctl delete unavailable >> "$LOG" 2>&1
  echo "[DONE] Xcode simulators cleaned" >> "$LOG"
else
  echo "[SKIP] Xcode not installed" >> "$LOG"
fi

# Trash cleanup
echo "[START] Emptying Trash..." >> "$LOG"
rm -rf ~/.Trash/* \
  && echo "[DONE] Trash emptied" >> "$LOG" \
  || echo "[ERROR] Trash cleanup failed" >> "$LOG"

echo "===== [MONTHLY CLEANUP END] =====" >> "$LOG"
echo >> "$LOG"