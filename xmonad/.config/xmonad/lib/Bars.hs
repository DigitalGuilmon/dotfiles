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

-- Usa dynamicLogString para generar el log como String y enviarlo manualmente
-- a cada barra. Evita llamar dynamicLogWithPP dos veces (la segunda sobrescribe
-- el estado interno de la primera, causando actualizaciones perdidas).
myLogHook :: Handle -> Handle -> X ()
myLogHook xmprocTop xmprocBottom = do
    -- Barra superior: muestra layout y título (sin workspaces)
    topStr <- dynamicLogString xmobarPP
        { ppSep     = " <fc=#6272a4>|</fc> "
        , ppOrder   = \fields -> case fields of
              (_ws:l:t:_) -> [l, t]
              (_ws:l:_)   -> [l]
              _           -> []
        , ppLayout  = xmobarColor "#f1fa8c" ""
        , ppTitle   = xmobarColor "#8be9fd" "" . shorten 60
        }
    io $ hPutStrLn xmprocTop topStr

    -- Barra inferior: muestra solo workspaces
    botStr <- dynamicLogString xmobarPP
        { ppOrder           = \fields -> case fields of
              (ws:_) -> [ws]
              _      -> []
        , ppWsSep           = "    "
        , ppCurrent         = xmobarColor "#bd93f9" "" . wrap "[ " " ]"
        , ppVisible         = xmobarColor "#f8f8f2" ""
        , ppHidden          = xmobarColor "#6272a4" ""
        , ppHiddenNoWindows = xmobarColor "#44475a" ""
        }
    io $ hPutStrLn xmprocBottom botStr
