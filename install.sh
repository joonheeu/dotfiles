#!/usr/bin/env bash
# install.sh — Bootstrap dotfiles via GNU Stow

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_PACKAGES=(zsh git config scripts)

info()  { printf "\033[0;34m[info]\033[0m  %s\n" "$*"; }
ok()    { printf "\033[0;32m[ok]\033[0m    %s\n" "$*"; }
warn()  { printf "\033[0;33m[warn]\033[0m  %s\n" "$*"; }
err()   { printf "\033[0;31m[error]\033[0m %s\n" "$*" >&2; }

# ──────────────────────────────────────────────
# Dependency check
# ──────────────────────────────────────────────
require_stow() {
  if ! command -v stow &>/dev/null; then
    warn "stow not found. Installing via Homebrew..."
    brew install stow
  fi
}

# ──────────────────────────────────────────────
# Backup existing files before symlinking
# ──────────────────────────────────────────────
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up $target → $backup"
    mv "$target" "$backup"
  fi
}

backup_dotfiles() {
  info "Checking for existing dotfiles to back up..."
  backup_if_exists "$HOME/.zshrc"
  backup_if_exists "$HOME/.gitconfig"
  backup_if_exists "$HOME/.config/starship.toml"
  backup_if_exists "$HOME/.config/ghostty/config"
  backup_if_exists "$HOME/.config/mise/config.toml"
  # scripts dir — only back up if it's a real directory, not a symlink
  if [[ -d "$HOME/scripts" && ! -L "$HOME/scripts" ]]; then
    warn "Backing up $HOME/scripts → $HOME/scripts.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$HOME/scripts" "$HOME/scripts.bak.$(date +%Y%m%d_%H%M%S)"
  fi
}

# ──────────────────────────────────────────────
# Stow packages
# ──────────────────────────────────────────────
stow_packages() {
  cd "$DOTFILES_DIR"
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
      info "Stowing: $pkg"
      stow --target="$HOME" --restow "$pkg"
      ok "$pkg linked"
    else
      warn "Package not found, skipping: $pkg"
    fi
  done
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
  info "Starting dotfiles install from: $DOTFILES_DIR"
  require_stow
  backup_dotfiles
  stow_packages
  ok "All done! Restart your shell or run: source ~/.zshrc"
}

main "$@"
