module Keys (myKeys) where

import XMonad

import Keys.System (systemKeys)
import Keys.Launchers (launcherKeys)
import Keys.Scratchpads (scratchpadKeys)
import Keys.Utilities (utilityKeys)
import Keys.Productivity (productivityKeys)
import Keys.Search (searchKeys)
import Keys.Windows (windowKeys)
import Keys.Workspaces (workspaceKeys)
import Keys.Multimedia (multimediaKeys)

myKeys :: [(String, X ())]
myKeys = concat
    [ systemKeys
    , launcherKeys
    , scratchpadKeys
    , utilityKeys
    , productivityKeys
    , searchKeys
    , windowKeys
    , workspaceKeys
    , multimediaKeys
    -- Desactivar keybinds por defecto de XMonad que no usamos
    -- M-S-p lanza gmrun (no instalado), lo anulamos
    , [("M-S-p", return ())]
    ]
