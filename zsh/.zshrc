# =========================================================
# .zshrc Authoring Guide (Read Before Editing)
# Maintain structure, order, and clarity of this file
# =========================================================
#
# This file is organized into ordered sections.
# DO NOT randomly insert code — always follow the rules below.
#
# ---------------------------------------------------------
# Rules
# ---------------------------------------------------------
#
# • Respect Section Order (Top → Bottom execution)
#   - Sections must remain in logical execution order.
#   - Earlier sections must not depend on later sections.
#
# • One Responsibility per Section
#   - Each section must have a single clear purpose.
#   - Do not mix aliases, functions, and env variables.
#
# • Use Standard Section Format
#   - Every section must follow:
#
#     # =========================================================
#     # Section Name
#     # Short one-line description
#     # =========================================================
#
# • Keep Comments Minimal
#   - Use English only.
#   - Prefer short, functional descriptions.
#
# • Plugin Separation (CRITICAL)
#   - Oh My Zsh: built-in plugins ONLY
#   - Zinit: external plugins ONLY
#   - Never load the same plugin in both systems
#
# • Section Order Convention
#   - Arrange sections in this general flow:
#     Early Init → Env → Runtime → OMZ → Shell Config →
#     Completion → Conditional → Functions → Keybinds →
#     Aliases → Zinit → Auto-Appended
#
# • PATH Management
#   - Higher priority paths come first.
#   - Avoid duplicates.
#   - Do not modify PATH after plugin initialization.
#
# • Aliases Guidelines
#   - Group by purpose (general, git, system, navigation).
#   - Avoid name conflicts.
#   - Prefer clarity over overly short names.
#
# • Functions Guidelines
#   - Keep functions small and single-purpose.
#   - Move complex logic to ~/scripts.
#
# • Completion Guidelines
#   - Register completion paths before activation.
#   - Avoid multiple compinit calls.
#
# • Performance Awareness
#   - Avoid heavy operations at startup.
#   - Use lazy loading when possible.
#
# • Auto-Appended Section (STRICT)
#   - Must remain at the very bottom.
#   - Do not edit manually.
#   - Used by scripts via >> ~/.zshrc
#
# ---------------------------------------------------------
# Philosophy
# ---------------------------------------------------------
#
# - Keep startup fast
# - Keep structure predictable
# - Keep responsibilities separated
# - Treat .zshrc as system config, not a playground
#
# =========================================================



# =========================================================
# Early Init
# Initialize environment before anything else
# =========================================================

# locale
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# base PATH (higher priority first)
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# default editor (may be overridden later)
export EDITOR='code'

# =========================================================
# Environment Variables
# Global environment variables
# =========================================================

export NODE_ENV=development

# =========================================================
# Runtime Init (toolchain activation)
# Activate language/version managers
# =========================================================

# mise (runtime/version manager)
eval "$(mise activate zsh)"

# ========================================================
# Oh My Zsh Setup
# Core shell framework initialization
# =========================================================

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# OMZ built-in plugins only (no external plugins)
plugins=(
    git 
    sudo
    macos
    docker
    extract
    zsh-bat
    colorize
    web-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
)

# OMZ options
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# load OMZ
source $ZSH/oh-my-zsh.sh

# =========================================================
# Post-OMZ Config (history & shell behavior)
# Configure shell behavior after OMZ load
# =========================================================

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST

# =========================================================
# Completion Setup
# Register additional completion sources
# =========================================================

# docker completion path
fpath=(~/.docker/completions $fpath)

# =========================================================
# Conditional Config (local vs remote)
# Environment-specific overrides
# =========================================================

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code'
fi

# =========================================================
# Custom Functions (CLI utilities)
# User-defined shell functions
# =========================================================

generate_scripts_bin() {
  local src="$HOME/scripts"
  local dst="$HOME/.local/bin"

  mkdir -p "$dst"

  find "$src" -type f | while read -r file; do
    local name
    name=$(basename "$file")
    name="${name%.*}"
    ln -sf "$file" "$dst/$name"
  done
}

# =========================================================
# Key Bindings
# Custom keyboard shortcuts
# =========================================================

bindkey '^U' backward-kill-line
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# =========================================================
# Aliases (general)
# Basic command shortcuts
# =========================================================

alias c='clear'
alias l='ls -l'
alias ls='ls -G'
alias ll='ls -alF'
alias la='ls -A'
alias rld='source ~/.zshrc && echo "~/.zshrc reloaded."'

# =========================================================
# Aliases (git)
# Git workflow shortcuts
# =========================================================

alias g='git'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# =========================================================
# Aliases (safe defaults)
# Safer file operations
# =========================================================

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# =========================================================
# Aliases (system / utilities)
# Useful system helpers
# =========================================================

alias ports='lsof -i -P -n | grep LISTEN'
alias ding='afplay /System/Library/Sounds/Funk.aiff'

# =========================================================
# Aliases (navigation)
# Quick directory access
# =========================================================

alias work='cd ~/workspace'
alias docs='cd ~/Documents'
alias scripts='cd ~/scripts'
alias desktop='cd ~/Desktop'
alias dotfiles='cd ~/.dotfiles'
alias downloads='cd ~/Downloads'

# =========================================================
# Aliases (custom tools)
# Personal CLI shortcuts
# =========================================================

alias reload='source ~/.zshrc'
alias secret='~/scripts/security/secret_env.sh'
alias claude='claude --dangerously-skip-permissions'
alias cld='claude'
alias oc='opencode'
alias sync-scripts='generate_scripts_bin'
alias disk-usage="du -sh * | sort -h"

# =========================================================
# Zinit (plugin manager)
# External plugins (loaded after OMZ)
# =========================================================

# auto install (optional)
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  command mkdir -p "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit \
    "$HOME/.local/share/zinit/zinit.git"
fi

# load zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# completion
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# plugins (external only)
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light fdellwing/zsh-bat
zinit light MichaelAquilina/zsh-auto-notify

# =========================================================
# Auto Appended Config (do not edit)
# Reserved for scripts using >> ~/.zshrc
# =========================================================

# --- appended configs below ---# OpenCode wrapper that syncs Claude agents before starting
alias opencode="~/.config/opencode/opencode-wrapper"
