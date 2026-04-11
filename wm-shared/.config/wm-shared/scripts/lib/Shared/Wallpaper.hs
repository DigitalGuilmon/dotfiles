module Shared.Wallpaper 
    ( changeWallpaper
    , restoreWallpaper
    ) where

import XMonad

-- Acción para descargar un wallpaper aleatorio de waifu.im
-- Usa agrupación explícita para que cada paso tenga su propio mensaje de error
changeWallpaper :: X ()
changeWallpaper = spawn $ unwords
    [ "mkdir -p ~/.cache &&"
    , "url=$(curl -s --max-time 10 'https://api.waifu.im/search?is_nsfw=false&orientation=LANDSCAPE' | jq -r '.images[0].url');"
    , "if [ \"$url\" != \"null\" ] && [ -n \"$url\" ]; then"
    , "  { curl -sL --max-time 30 \"$url\" -o ~/.cache/wallpaper.jpg ||"
    , "    { notify-send '⚠️ Wallpaper' 'Error al descargar la imagen'; exit 1; }; } &&"
    , "  { file ~/.cache/wallpaper.jpg | grep -qi 'image' ||"
    , "    { notify-send '⚠️ Wallpaper' 'El archivo descargado no es una imagen válida'; exit 1; }; } &&"
    , "  { feh --bg-fill ~/.cache/wallpaper.jpg ||"
    , "    notify-send '⚠️ Wallpaper' 'Error al establecer el fondo de pantalla'; };"
    , "else"
    , "  notify-send '⚠️ Wallpaper' 'No se pudo obtener URL de la API';"
    , "fi"
    ]

-- Acción para restaurar el fondo al iniciar Xmonad
restoreWallpaper :: X ()
restoreWallpaper = spawn "if [ -f ~/.cache/wallpaper.jpg ]; then feh --bg-fill ~/.cache/wallpaper.jpg; else notify-send '🖼️ Wallpaper' 'No se encontró wallpaper en cache. Usa Super+U para descargar uno.'; fi"
