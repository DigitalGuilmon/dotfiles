-- Archivo: xmonad/.config/xmonad/xmonad.hs

import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.ManageDocks (docks)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe, hPutStrLn)

import Variables
import Layouts
import Rules
import Startup
import Keys

main :: IO ()
main = do
    xmprocTop    <- spawnPipe "xmobar ~/.config/xmobar/xmobar-top.hs"
    xmprocBottom <- spawnPipe "xmobar ~/.config/xmobar/xmobar-bottom.hs"
    
    xmonad $ ewmhFullscreen $ ewmh $ docks $ def
        { terminal           = myTerminal
        , modMask            = myModMask
        , workspaces         = myWorkspaces
        , manageHook         = myManageHook
        , layoutHook         = myLayout
        , startupHook        = myStartupHook
        , borderWidth        = myBorderWidth
        , normalBorderColor  = "#282c34"
        , focusedBorderColor = "#c678dd"
        
        , logHook            = do
            -- Barra SUPERIOR: [Layout] }{ [Título]
            dynamicLogWithPP xmobarPP
                { ppOutput  = hPutStrLn xmprocTop
                -- Usamos el separador de Xmobar para dividir Layout y Título
                , ppSep     = "}{" 
                -- ppOrder determina el orden: [Layout, Título]. 
                -- Al unirse con "}{", Xmobar ve "Layout}{Título"
                , ppOrder   = \(ws:l:t:_) -> [l, t] 
                , ppTitle   = xmobarColor "#50fa7b" "" . shorten 80
                , ppLayout  = xmobarColor "#f1fa8c" ""
                }
            -- Barra INFERIOR: [Workspaces]
            dynamicLogWithPP xmobarPP
                { ppOutput  = hPutStrLn xmprocBottom
                , ppOrder   = \(ws:l:t:_) -> [ws]
                , ppWsSep   = "    "
                , ppCurrent = xmobarColor "#bd93f9" "" . wrap "[ " " ]"
                , ppVisible = xmobarColor "#f8f8f2" ""
                , ppHidden  = xmobarColor "#6272a4" ""
                }
        } `additionalKeysP` myKeys
