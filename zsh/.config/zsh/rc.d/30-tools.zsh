# ===============================================================
# Inicializaciones y herramientas externas
# ===============================================================

has_cmd zoxide && eval "$(zoxide init zsh)"
has_cmd thefuck && eval "$(thefuck --alias)"

# FZF + FD
if has_cmd fd; then
  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if has_cmd bat; then
  export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"
fi

# Color de sugerencias (gris suave)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#808080'

# ===============================================================
# Atajos de teclado para herramientas TUI
# Alt+v -> lvim | Alt+g -> lazygit | Alt+d -> lazydocker
# ===============================================================
if [[ -o interactive ]]; then
  _open_lvim_widget() {
    zle -I
    if has_cmd lvim; then
      lvim
    else
      print -u2 'lvim no está instalado.'
    fi
    zle reset-prompt
  }

  _open_lazygit_widget() {
    zle -I
    if has_cmd lazygit; then
      lazygit
    else
      print -u2 'lazygit no está instalado.'
    fi
    zle reset-prompt
  }

  _open_lazydocker_widget() {
    zle -I
    if has_cmd lazydocker; then
      lazydocker
    else
      print -u2 'lazydocker no está instalado.'
    fi
    zle reset-prompt
  }

  zle -N open-lvim-widget _open_lvim_widget
  zle -N open-lazygit-widget _open_lazygit_widget
  zle -N open-lazydocker-widget _open_lazydocker_widget

  bindkey '^[v' open-lvim-widget
  bindkey '^[g' open-lazygit-widget
  bindkey '^[d' open-lazydocker-widget
fi
