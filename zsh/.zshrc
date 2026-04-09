# ===============================================================
# Cargar variables locales/secretas si el archivo existe
# ===============================================================
if [[ -r ~/.secrets ]]; then
  source ~/.secrets
fi

# ===============================================================
# Optimización de arranque (P10K Instant Prompt)
# ===============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===============================================================
# Cargar configuración desacoplada
# ===============================================================
ZSHRC_D="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/rc.d"
for rc_file in "$ZSHRC_D"/*.zsh(N); do
  [[ -r "$rc_file" ]] && source "$rc_file"
done
unset rc_file ZSHRC_D
