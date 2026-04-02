module Startup where

import XMonad
import XMonad.Util.SpawnOnce (spawnOnce)

myStartupHook :: X ()
myStartupHook = do
    spawnOnce "picom --config ~/.config/picom/picom.conf &"
    spawnOnce "feh --bg-fill ~/Descargas/wall.png"
    -- Lanzar la barra superior e inferior usando tus archivos .hs
--    spawnOnce "xmobar ~/.config/xmobar/xmobar-bottom.hs"
 --   spawnOnce "xmobar ~/.config/xmobar/xmobar-top.hs"
