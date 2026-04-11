module Shared.Menu.SystemInfo (systemInfo) where

import Common.SystemInfo (systemInfoOptions)
import XMonad
import Shared.Utils (rofiSelect)

-- Dashboard de información del sistema usando rofi
-- Muestra la info seleccionada con notify-send
systemInfo :: X ()
systemInfo = do
    res <- rofiSelect "xmonad-system-info" "SysInfo:" ["-i"] (unlines (map fst systemInfoOptions))
    case lookup res systemInfoOptions of
        Just command -> spawn command
        Nothing -> return ()
