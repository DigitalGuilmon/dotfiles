# ===============================================================
# Plugins (orden óptimo para evitar bugs de colores)
# ===============================================================
plugins=(
  git
  thefuck
  fzf
  tmux
  extract
  web-search
  zsh-autosuggestions
  fzf-tab
  zsh-syntax-highlighting # Siempre al final
)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# ===============================================================
# Powerlevel10k
# ===============================================================
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh
