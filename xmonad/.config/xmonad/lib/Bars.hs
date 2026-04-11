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
        , ppSep     = " <fc=#6272a4>|</fc> "
        , ppOrder   = \fields -> case fields of
              (_ws:l:t:_) -> [l, t]
              (_ws:l:_)   -> [l]
              _           -> []
        , ppLayout  = xmobarColor "#f1fa8c" ""
        , ppTitle   = xmobarColor "#8be9fd" "" . shorten 60
        }
    dynamicLogWithPP xmobarPP
        { ppOutput          = hPutStrLn xmprocBottom
        , ppOrder           = \fields -> case fields of
              (ws:_) -> [ws]
              _      -> []
        , ppWsSep           = "    "
        , ppCurrent         = xmobarColor "#bd93f9" "" . wrap "[ " " ]"
        , ppVisible         = xmobarColor "#f8f8f2" ""
        , ppHidden          = xmobarColor "#6272a4" ""
        , ppHiddenNoWindows = xmobarColor "#44475a" ""
        }
