# dotfiles

Personal development environment configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Package | Files | Description |
|---------|-------|-------------|
| `zsh` | `.zshrc` | Shell config — Oh My Zsh, Zinit plugins, aliases, functions |
| `git` | `.gitconfig` | Git user settings, LFS, HTTP buffer |
| `config` | `.config/starship.toml` | Starship prompt theme |
| | `.config/ghostty/config` | Ghostty terminal (Dracula theme, JetBrains Mono) |
| | `.config/mise/config.toml` | mise runtime versions (Node, Python, Bun, etc.) |
| `scripts` | `scripts/claude/` | Claude Code helper scripts (master agent, vibe-coder) |
| | `scripts/dev/` | Editor extension cleaner |
| | `scripts/mac/` | macOS storage cleanup, dictation fix |
| | `scripts/security/` | Keychain-based secret manager, password generator |
| | `scripts/system/` | Daily/weekly/monthly cleanup, kill-port |

## Install

```bash
git clone https://github.com/joonheeu/dotfiles ~/.dotfiles
bash ~/.dotfiles/install.sh
```

The script will:
1. Install `stow` via Homebrew if not present
2. Back up any existing dotfiles as `*.bak.YYYYMMDD_HHMMSS`
3. Symlink all packages into `~`

## Structure

```
~/.dotfiles/
├── zsh/
│   └── .zshrc
├── git/
│   └── .gitconfig
├── config/
│   └── .config/
│       ├── starship.toml
│       ├── ghostty/config
│       └── mise/config.toml
├── scripts/               ← ~/scripts 직접 심링크
│   ├── claude/
│   ├── dev/
│   ├── mac/
│   ├── security/
│   └── system/
└── install.sh
```

Stow mirrors each package directory into `~`. For example, `zsh/.zshrc` becomes `~/.zshrc`.

## Adding a New Package

```bash
# 1. Create the package directory mirroring the target path
mkdir -p ~/.dotfiles/myapp/.config/myapp

# 2. Move your config into it
mv ~/.config/myapp/config ~/.dotfiles/myapp/.config/myapp/config

# 3. Symlink with stow
cd ~/.dotfiles && stow myapp

# 4. Add the package name to install.sh → STOW_PACKAGES
```

## Updating

Editing any symlinked file (e.g. `~/.zshrc`) directly modifies the file inside `~/.dotfiles`. Just commit the change:

```bash
cd ~/.dotfiles
git add -p
git commit -m "chore(zsh): update aliases"
git push
```

## Requirements

- macOS (Apple Silicon)
- [Homebrew](https://brew.sh)
- [GNU Stow](https://www.gnu.org/software/stow/) — installed automatically by `install.sh`
