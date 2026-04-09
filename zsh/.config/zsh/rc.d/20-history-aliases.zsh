# ===============================================================
# Historial
# ===============================================================
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# ===============================================================
# Aliases y funciones
# ===============================================================
alias cls='clear'
alias zconf='lvim ~/.zshrc'
alias tconf='lvim ~/.tmux.conf.local' # Apunta al archivo de Oh My Tmux
alias reload='source ~/.zshrc'

if has_cmd brew; then
  alias update='brew update && brew upgrade'
elif has_cmd pacman; then
  alias update='sudo pacman -Syu'
fi

if has_cmd eza; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first'
  alias tree='eza --tree --icons'
fi

has_cmd bat && alias cat='bat --style=plain'
has_cmd btop && alias top='btop'

r() {
  if ! has_cmd ranger; then
    echo 'ranger no está instalado.'
    return 1
  fi

  local chooser_file="$HOME/.rangerdir"
  local target_dir

  ranger --choosedir="$chooser_file" "$@"

  if [[ -r "$chooser_file" ]]; then
    IFS= read -r target_dir < "$chooser_file"
    [[ -d "$target_dir" ]] && cd -- "$target_dir"
  fi
}

# Truco: Cerrar terminal al salir de tmux (evita el "doble exit")
[[ -z "$TMUX" ]] || alias exit='exit && exit'
