#!/bin/bash

LOG="$HOME/logs/cleanup-daily.log"
mkdir -p "$(dirname "$LOG")"

echo "===== $(date) [DAILY CLEANUP START] =====" >> "$LOG"

# Clean macOS user caches
echo "[START] Cleaning user caches..." >> "$LOG"
rm -rf ~/Library/Caches/* \
  && echo "[DONE] User caches cleared" >> "$LOG" \
  || echo "[ERROR] Cache cleanup failed" >> "$LOG"

# Homebrew cleanup
if command -v brew >/dev/null; then
  echo "[START] Homebrew cleanup..." >> "$LOG"
  brew cleanup -s >> "$LOG" 2>&1
  brew autoremove >> "$LOG" 2>&1
  echo "[DONE] Homebrew cleaned" >> "$LOG"
else
  echo "[SKIP] Homebrew not installed" >> "$LOG"
fi

# Node (npm)
if command -v npm >/dev/null; then
  echo "[START] npm cache verify..." >> "$LOG"
  npm cache verify >> "$LOG" 2>&1
  echo "[DONE] npm cache verified" >> "$LOG"
else
  echo "[SKIP] npm not installed" >> "$LOG"
fi

# pnpm
if command -v pnpm >/dev/null; then
  echo "[START] pnpm store prune..." >> "$LOG"
  pnpm store prune >> "$LOG" 2>&1
  echo "[DONE] pnpm store pruned" >> "$LOG"
else
  echo "[SKIP] pnpm not installed" >> "$LOG"
fi

# Docker
if command -v docker >/dev/null; then
  echo "[START] Docker system prune..." >> "$LOG"
  docker system prune -af >> "$LOG" 2>&1
  echo "[DONE] Docker cleaned" >> "$LOG"
else
  echo "[SKIP] Docker not installed" >> "$LOG"
fi

# Clean old logs
echo "[START] Cleaning old logs (7 days)..." >> "$LOG"
find ~/Library/Logs -type f -mtime +7 -delete \
  && echo "[DONE] Old logs removed" >> "$LOG" \
  || echo "[ERROR] Log cleanup failed" >> "$LOG"

echo "===== [DAILY CLEANUP END] =====" >> "$LOG"
echo >> "$LOG"