module Scripts.Wallpaper 
    ( changeWallpaper
    , restoreWallpaper
    ) where

import XMonad

-- Acción para descargar un wallpaper de Anime aleatorio
-- 1. Usa 'curl' para obtener un JSON de waifu.im filtrando por imágenes apaisadas (LANDSCAPE)
-- 2. Extrae la URL de la imagen usando herramientas nativas de Linux (grep y cut)
-- 3. Descarga la imagen en ~/.cache/wallpaper.jpg y la aplica con 'feh'
changeWallpaper :: X ()
changeWallpaper = spawn "mkdir -p ~/.cache && url=$(curl -s \"https://api.waifu.im/search?is_nsfw=false&orientation=LANDSCAPE\" | grep -o '\"url\": \"[^\"]*\"' | head -n 1 | cut -d'\"' -f4) && curl -sL $url -o ~/.cache/wallpaper.jpg && feh --bg-fill ~/.cache/wallpaper.jpg"

-- Acción para restaurar el fondo al iniciar Xmonad
-- Intenta cargar la última imagen de anime guardada. Si no hay ninguna, usa tu wall.png de Descargas.
restoreWallpaper :: X ()
restoreWallpaper = spawn "feh --bg-fill ~/.cache/wallpaper.jpg || feh --bg-fill ~/Downloads/a.jpg"
