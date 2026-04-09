module Bars
    ( spawnBars
    , myLogHook
    ) where

import System.IO (Handle)
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe, hPutStrLn)

spawnBars :: IO (Handle, Handle)
spawnBars = do
    xmprocTop    <- spawnPipe "xmobar ~/.config/xmobar/xmobar-top.hs"
    xmprocBottom <- spawnPipe "xmobar ~/.config/xmobar/xmobar-bottom.hs"
    pure (xmprocTop, xmprocBottom)

myLogHook :: Handle -> Handle -> X ()
myLogHook xmprocTop xmprocBottom = do
    dynamicLogWithPP xmobarPP
        { ppOutput  = hPutStrLn xmprocTop
        , ppSep     = ""
        , ppOrder   = \(_ws:l:_t:_) -> [l]
        , ppLayout  = xmobarColor "#f1fa8c" ""
        }
    dynamicLogWithPP xmobarPP
        { ppOutput  = hPutStrLn xmprocBottom
        , ppOrder   = \(ws:_l:_t:_) -> [ws]
        , ppWsSep   = "    "
        , ppCurrent = xmobarColor "#bd93f9" "" . wrap "[ " " ]"
        , ppVisible = xmobarColor "#f8f8f2" ""
        , ppHidden  = xmobarColor "#6272a4" ""
        }
