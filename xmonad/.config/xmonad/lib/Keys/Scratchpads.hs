module Keys.Scratchpads where

import XMonad
import XMonad.Util.NamedScratchpad (namedScratchpadAction)

import Scratchpads (myScratchpads)

scratchpadKeys :: [(String, X ())]
scratchpadKeys =
    [ ("M-s",          namedScratchpadAction myScratchpads "terminal")    -- Terminal flotante
    , ("M-S-s",        namedScratchpadAction myScratchpads "vscode")      -- VS Code flotante
    , ("M-S-f",        namedScratchpadAction myScratchpads "filemanager") -- Thunar flotante
    , ("M-S-b",        namedScratchpadAction myScratchpads "btop")        -- Monitor de sistema flotante
    , ("M-S-n",        namedScratchpadAction myScratchpads "notes")       -- Notas rápidas flotante
    ]
