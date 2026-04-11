module Bars
    ( spawnBars
    , myLogHook
    ) where

import Control.Monad (filterM)
import Data.Maybe (listToMaybe)
import System.Directory (doesFileExist, getHomeDirectory)
import System.IO (Handle)
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Util.NamedScratchpad (scratchpadWorkspaceTag)
import XMonad.Util.Run (spawnPipe, hPutStrLn)

import Variables (resolveHomePath)

quoteArg :: String -> String
quoteArg = show

resolveXmobarPath :: IO FilePath
resolveXmobarPath = do
    home <- getHomeDirectory
    let candidates =
            [ home ++ "/.local/bin/xmobar"
            , "/usr/bin/xmobar"
            , "/bin/xmobar"
            ]
    existing <- filterM doesFileExist candidates
    pure $ maybe "xmobar" id (listToMaybe existing)

spawnXmobar :: FilePath -> IO Handle
spawnXmobar configPath = do
    xmobarPath <- resolveXmobarPath
    spawnPipe $ unwords [quoteArg xmobarPath, quoteArg configPath]

spawnBars :: IO (Handle, Handle)
spawnBars = do
    xmprocTop <- spawnXmobar =<< resolveHomePath ".config/xmobar/xmobar-top.hs"
    xmprocBottom <- spawnXmobar =<< resolveHomePath ".config/xmobar/xmobar-bottom.hs"
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
    catchIO $ hPutStrLn xmprocTop topStr

    -- Barra inferior: muestra solo workspaces (filtra el workspace interno NSP de scratchpads)
    botStr <- dynamicLogString $ filterOutWsPP [scratchpadWorkspaceTag] xmobarPP
        { ppOrder           = \fields -> case fields of
              (ws:_) -> [ws]
              _      -> []
        , ppWsSep           = "    "
        , ppCurrent         = xmobarColor "#bd93f9" "" . wrap "[ " " ]"
        , ppVisible         = xmobarColor "#f8f8f2" ""
        , ppHidden          = xmobarColor "#6272a4" ""
        , ppHiddenNoWindows = xmobarColor "#44475a" ""
        }
    catchIO $ hPutStrLn xmprocBottom botStr
