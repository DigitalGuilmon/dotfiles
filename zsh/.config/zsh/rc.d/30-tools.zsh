# ===============================================================
# Inicializaciones y herramientas externas
# ===============================================================

has_cmd zoxide && eval "$(zoxide init zsh)"
has_cmd thefuck && eval "$(thefuck --alias)"

# FZF + FD
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"

# Color de sugerencias (gris suave)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#808080'
