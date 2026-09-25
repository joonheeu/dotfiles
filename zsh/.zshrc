# Focused interactive shell configuration.

# Keep Homebrew-installed interactive commands available after `source ~/.zshrc`.
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"

# Oh My Zsh provides completion and a plugin boundary. Starship owns the prompt.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
zstyle ':omz:update' mode disabled
source "$ZSH/oh-my-zsh.sh"

# History is shared across terminal sessions without retaining duplicate noise.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Zinit manages the two interactive enhancements not provided by Oh My Zsh.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  zinit light zsh-users/zsh-autosuggestions
  zinit light zdharma-continuum/fast-syntax-highlighting
fi

# zoxide learns directory visits; use `z <query>` for fast navigation.
eval "$(zoxide init zsh)"

# Interactive command replacements. Keep fd and z separate from find and cd.
alias ls='eza --group-directories-first'
alias ll='eza -lah --git --group-directories-first'
alias la='eza -a'
alias lt='eza --tree --level=2'
alias cat='bat --paging=never'
alias df='duf'
alias du='dust'
alias ps='procs'
alias top='btop'
alias grep='rg'
alias c='clear'
alias reload='source ~/.zshrc'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ports='lsof -i -P -n | rg LISTEN'

# Keep this last so Starship is the only prompt renderer.
eval "$(starship init zsh)"
