#!/bin/bash

LOG="$HOME/logs/cleanup-weekly.log"
mkdir -p "$(dirname "$LOG")"

echo "===== $(date) [WEEKLY CLEANUP START] =====" >> "$LOG"

# Remove old node_modules (older than 30 days)
echo "[START] Removing old node_modules..." >> "$LOG"
find ~/workspace -name "node_modules" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null \
  && echo "[DONE] Old node_modules removed" >> "$LOG" \
  || echo "[ERROR] node_modules cleanup failed" >> "$LOG"

# Python cache
echo "[START] Cleaning pip cache..." >> "$LOG"
rm -rf ~/.cache/pip \
  && echo "[DONE] pip cache cleared" >> "$LOG" \
  || echo "[ERROR] pip cache cleanup failed" >> "$LOG"

# Downloads cleanup
echo "[START] Cleaning old Downloads..." >> "$LOG"
find ~/Downloads -type f -mtime +30 -delete \
  && echo "[DONE] Downloads cleaned" >> "$LOG" \
  || echo "[ERROR] Downloads cleanup failed" >> "$LOG"

# Docker images
if command -v docker >/dev/null; then
  echo "[START] Pruning Docker images..." >> "$LOG"
  docker image prune -a -f >> "$LOG" 2>&1
  echo "[DONE] Docker images pruned" >> "$LOG"
else
  echo "[SKIP] Docker not installed" >> "$LOG"
fi

echo "===== [WEEKLY CLEANUP END] =====" >> "$LOG"
echo >> "$LOG"