module Scripts.System.Wallpaper 
    ( changeWallpaper
    , restoreWallpaper
    ) where

import XMonad

-- Acción para descargar un wallpaper aleatorio de waifu.im
changeWallpaper :: X ()
changeWallpaper = spawn "mkdir -p ~/.cache && url=$(curl -s --max-time 10 'https://api.waifu.im/images?IsNsfw=False&Orientation=Landscape' | jq -r '.items[0].url') && if [ \"$url\" != \"null\" ] && [ -n \"$url\" ]; then curl -sL --max-time 30 \"$url\" -o ~/.cache/wallpaper.jpg && file ~/.cache/wallpaper.jpg | grep -qi 'image' && feh --bg-fill ~/.cache/wallpaper.jpg || notify-send '⚠️ Wallpaper' 'El archivo descargado no es una imagen válida'; fi"

-- Acción para restaurar el fondo al iniciar Xmonad
restoreWallpaper :: X ()
restoreWallpaper = spawn "if [ -f ~/.cache/wallpaper.jpg ]; then feh --bg-fill ~/.cache/wallpaper.jpg; else notify-send '🖼️ Wallpaper' 'No se encontró wallpaper en cache. Usa Super+W para descargar uno.'; fi"
