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
alias zconf='lvim ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/rc.d'
alias tconf='lvim ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf.local' # Apunta al archivo local de Oh My Tmux
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

function r() {
  if ! has_cmd ranger; then
    echo 'ranger no está instalado.'
    return 1
  fi

  local chooser_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ranger"
  local chooser_file="$chooser_dir/choosedir"
  local target_dir

  mkdir -p "$chooser_dir" 2>/dev/null
  ranger --choosedir="$chooser_file" "$@"

  if [[ -r "$chooser_file" ]]; then
    IFS= read -r target_dir < "$chooser_file"
    if [[ -n "$target_dir" && -d "$target_dir" ]]; then
      if ! cd -- "$target_dir"; then
        echo "No se pudo cambiar al directorio: $target_dir"
        return 1
      fi
    fi
  fi
}

# Truco: Cerrar terminal al salir de tmux (evita el "doble exit")
[[ -z "$TMUX" ]] || alias exit='exit && exit'
