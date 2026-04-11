module Startup where

import XMonad
import XMonad.Util.SpawnOnce (spawnOnce)
import Scripts.System.Wallpaper (restoreWallpaper) -- Importamos la función de tu script

myStartupHook :: X ()
myStartupHook = do
    -- 1. Fija el cursor normal del ratón (por defecto suele ser una X)
    spawnOnce "xsetroot -cursor_name left_ptr"
    
    -- 2. Composición y Fondo de pantalla
    spawnOnce "picom --config ~/.config/picom/picom.conf"
    
    -- Eliminamos la llamada directa a feh para evitar la condición de carrera
    restoreWallpaper 
    
    -- 3. Bandeja del sistema (Systray)
    -- Xmobar no tiene bandeja nativa. Si instalas 'trayer', descomenta esta línea.
    -- (Nota: Deberás reducir el ancho de xmobar-top.hs al 90-95% para hacerle espacio)
    -- spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --transparent true --alpha 0 --tint 0x282a36 --height 36 &"

    -- 4. Lanzamiento de barras
    -- Lanzar la barra superior e inferior usando tus archivos .hs
    -- (Están comentados asumiendo que usas spawnPipe en tu xmonad.hs principal)
    --spawnOnce "xmobar ~/.config/xmobar/xmobar-bottom.hs"
    --spawnOnce "xmobar ~/.config/xmobar/xmobar-top.hs"
