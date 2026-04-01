#!/bin/bash

LOG="$HOME/logs/cleanup-light.log"
mkdir -p "$(dirname "$LOG")"

log() {
  echo "$1" | tee -a "$LOG"
}

log "===== $(date) [LIGHT CLEANUP START] ====="

# Clean old temp files (older than 3 days)
log "[START] Cleaning /tmp files..."
find /tmp -type f -mtime +3 -delete 2>/dev/null \
  && log "[DONE] /tmp cleaned" \
  || log "[ERROR] /tmp cleanup failed"

# Remove broken symlinks in home directory
log "[START] Removing broken symlinks..."
find "$HOME" -xtype l -delete 2>/dev/null \
  && log "[DONE] Broken symlinks removed" \
  || log "[ERROR] Symlink cleanup failed"

log "===== [LIGHT CLEANUP END] ====="
log