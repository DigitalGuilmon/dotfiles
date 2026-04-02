#!/bin/bash


# 2. Instalar herramientas de sistema (Aliases y dependencias)
echo "📦 Instalando herramientas Rust y utilidades..."
sudo pacman -S eza bat fzf fd zoxide thefuck btop tmux ranger pyenv

# Definir ruta de plugins personalizados
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# 4. Instalar Tema Powerlevel10k
echo "🎨 Instalando Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k 2>/dev/null || echo "P10k ya instalado"

# 5. Instalar Plugins Externos
echo "🔌 Instalando plugins de ZSH..."

# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions 2>/dev/null

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting 2>/dev/null

# fzf-tab
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM}/plugins/fzf-tab 2>/dev/null

echo "✅ Instalación completada."
echo "⚠️  RECUERDA: Copia tu configuración al archivo ~/.zshrc y luego ejecuta 'source ~/.zshrc'"
