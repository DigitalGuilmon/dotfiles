# ===============================================================
# Cargar variables locales/secretas si el archivo existe
if [[ -f ~/.secrets ]]; then
  source ~/.secrets
fi
# 1. OPTIMIZACIÓN DE ARRANQUE (P10K Instant Prompt)
# ===============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===============================================================
# 2. RUTAS Y VARIABLES GLOBALES
# ===============================================================
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/Users/aldodeveloper/.antigravity/antigravity/bin:$PATH"

# ===============================================================
# 3. CONFIGURACIÓN PRE-OH MY ZSH (Vital para el plugin tmux)
# ===============================================================
ZSH_THEME="powerlevel10k/powerlevel10k"

# Configuración de Tmux (Debe ir antes de 'source $ZSH/oh-my-zsh.sh')
ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_AUTOCONNECT=true
# Evitar tmux dentro de la terminal de VS Code para no saturar la pantalla
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  ZSH_TMUX_AUTOSTART=false
fi

# ===============================================================
# 4. PLUGINS (Orden óptimo para evitar bugs de colores)
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

source $ZSH/oh-my-zsh.sh

# ===============================================================
# 5. CONFIGURACIÓN DE POWERLEVEL10K & HISTORIAL
# ===============================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# ===============================================================
# 6. ALIASES NIVEL DIOS (M4 Optimized)
# ===============================================================
alias cls='clear'
alias update='brew update && brew upgrade'
alias zconf='lvim ~/.zshrc'
alias tconf='lvim ~/.tmux.conf.local' # Apunta al archivo de 'Oh My Tmux'
alias reload='source ~/.zshrc'

# Herramientas modernas (Rust alternatives)
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first'
alias tree='eza --tree --icons'
alias cat='bat --style=plain'
alias top='btop'
alias r='ranger --choosedir=$HOME/.rangerdir && cd "$(cat $HOME/.rangerdir)"'
# Truco: Cerrar terminal al salir de tmux (evita el "doble exit")
[[ -z "$TMUX" ]] || alias exit='exit && exit'

# ===============================================================
# 7. INICIALIZACIONES Y HERRAMIENTAS EXTERNAS
# ===============================================================
eval "$(zoxide init zsh)"
eval $(thefuck --alias)

# FZF + FD (Búsqueda ultra rápida en M4)
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# Vista previa en FZF usando 'bat'
export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"

# Color de las sugerencias (gris suave)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"
export PATH="$PATH:/Users/aldodeveloper/Library/Python/3.9/bin"
