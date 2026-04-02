import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.ManageDocks (docks)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe, hPutStrLn)

-- Importación de módulos locales
import Variables
import Layouts
import Rules
import Startup
import Keys

main :: IO ()
main = do
    -- Iniciamos las barras y capturamos sus procesos (pipes)
    xmprocTop    <- spawnPipe "xmobar ~/.config/xmonad/xmobar-top.hs"
    xmprocBottom <- spawnPipe "xmobar ~/.config/xmonad/xmobar-bottom.hs"
    
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
        , logHook            = dynamicLogWithPP xmobarPP
            { ppOutput = \x -> hPutStrLn xmprocTop x >> hPutStrLn xmprocBottom x
            , ppCurrent = xmobarColor "#bd93f9" "" . wrap "[" "]"
            , ppVisible = xmobarColor "#f8f8f2" ""
            , ppHidden  = xmobarColor "#6272a4" ""
            , ppTitle   = xmobarColor "#50fa7b" "" . shorten 60
            }
        } `additionalKeysP` myKeys
