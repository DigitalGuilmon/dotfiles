#!/bin/bash

DIR="$HOME/Videos/Wallpapers/Universe"

# 1. Comprobar si hay algún video en la carpeta
if [ -z "$(ls -A "$DIR" 2>/dev/null | grep -E '\.mp4$|\.webm$')" ]; then
    echo "❌ No hay videos en $DIR."
    echo "Usa yt-dlp para descargar uno desde YouTube primero."
    exit 1
fi

# 2. Seleccionar un video aleatorio de la carpeta
VIDEO=$(find "$DIR" -type f \( -name "*.mp4" -o -name "*.webm" \) | shuf -n 1)

# 3. Limpiar procesos previos
pkill mpvpaper

# 4. Ejecutar optimizado para tu gráfica AMD
echo "🚀 Iniciando mpvpaper con: $VIDEO"
mpvpaper -o "--hwdec=vaapi --vo=libmpv --loop-playlist --no-audio --msg-level=all=no" "*" "$VIDEO" &
