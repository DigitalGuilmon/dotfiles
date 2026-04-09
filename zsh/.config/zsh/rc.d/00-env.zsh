# ===============================================================
# Entorno base y rutas
# ===============================================================

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

path_prepend_if_dir() {
  [[ -d "$1" ]] && path=("$1" "${path[@]}")
}

path_append_if_dir() {
  [[ -d "$1" ]] && path+=("$1")
}

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
typeset -gU path PATH

path_prepend_if_dir "$HOME/.local/bin"
path_prepend_if_dir "$HOME/.npm-global/bin"
path_append_if_dir "$HOME/.antigravity/antigravity/bin"
for py_bin in "$HOME"/Library/Python/*/bin(N); do
  path_append_if_dir "$py_bin"
done
unset py_bin

# ===============================================================
# Configuración pre-Oh My Zsh (vital para plugin tmux)
# ===============================================================
ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_AUTOCONNECT=true

# Evitar tmux dentro de la terminal de VS Code para no saturar la pantalla
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  ZSH_TMUX_AUTOSTART=false
fi
