import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.ManageDocks (docks)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe, hPutStrLn)

-- Importación de tus módulos locales
import Variables
import Layouts
import Rules
import Startup
import Keys

main :: IO ()
main = do
    -- 1. Rutas corregidas para xmobar según la estructura de tu carpeta
    xmprocTop    <- spawnPipe "xmobar ~/.config/xmobar/xmobar-top.hs"
    xmprocBottom <- spawnPipe "xmobar ~/.config/xmobar/xmobar-bottom.hs"
    
    xmonad $ ewmhFullscreen $ ewmh $ docks $ def
        { terminal           = myTerminal       -- Definido en Variables.hs
        , modMask            = myModMask        -- Definido en Variables.hs
        , workspaces         = myWorkspaces     -- Definido en Variables.hs
        , manageHook         = myManageHook     -- Definido en Rules.hs
        , layoutHook         = myLayout         -- Definido en Layouts.hs
        , startupHook        = myStartupHook    -- Definido en Startup.hs
        , borderWidth        = myBorderWidth    -- Definido en Variables.hs
        , normalBorderColor  = "#282c34"
        , focusedBorderColor = "#c678dd"
        
        -- 2. LogHook optimizado para separar la información entre barras
        , logHook            = do
            -- Salida para la barra SUPERIOR (Workspaces y Layout)
            dynamicLogWithPP xmobarPP
                { ppOutput  = hPutStrLn xmprocTop
                , ppCurrent = xmobarColor "#bd93f9" "" . wrap "[" "]"
                , ppVisible = xmobarColor "#f8f8f2" ""
                , ppHidden  = xmobarColor "#6272a4" ""
                , ppTitle   = const ""  -- No mostramos el título arriba para no duplicar
                }
            -- Salida para la barra INFERIOR (Título de ventana activa)
            dynamicLogWithPP xmobarPP
                { ppOutput  = hPutStrLn xmprocBottom
                , ppOrder   = \xs -> case xs of
                    (_:_:t:_) -> [t]
                    _         -> [] -- Patrón seguro para evitar que XMonad crashee
                , ppTitle   = xmobarColor "#50fa7b" "" . shorten 80
                }
        } `additionalKeysP` myKeys -- Definido en Keys.hs
