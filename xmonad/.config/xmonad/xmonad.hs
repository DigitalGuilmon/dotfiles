-- Archivo: xmonad/.config/xmonad/xmonad.hs

import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.ManageDocks (docks)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)

import Variables
import Layouts
import Rules
import Startup
import Keys
import Bars

main :: IO ()
main = do
    (xmprocTop, xmprocBottom) <- spawnBars
    
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
        , logHook            = myLogHook xmprocTop xmprocBottom
        , handleEventHook    = myHandleEventHook
        } `additionalKeysP` myKeys
