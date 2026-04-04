module Scripts.Wallpaper 
    ( changeWallpaper
    , restoreWallpaper
    ) where

import XMonad

-- Acción para descargar un wallpaper aleatorio de waifu.im
changeWallpaper :: X ()
changeWallpaper = spawn "mkdir -p ~/.cache && url=$(curl -s 'https://api.waifu.im/images?IsNsfw=False&Orientation=Landscape' | jq -r '.items[0].url') && if [ \"$url\" != \"null\" ] && [ -n \"$url\" ]; then curl -sL \"$url\" -o ~/.cache/wallpaper.jpg && feh --bg-fill ~/.cache/wallpaper.jpg; fi"

-- Acción para restaurar el fondo al iniciar Xmonad
restoreWallpaper :: X ()
restoreWallpaper = spawn "feh --bg-fill ~/.cache/wallpaper.jpg || feh --bg-fill ~/Downloads/a.jpg"
