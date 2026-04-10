module Keys.Utilities where

import XMonad

import Scripts.Multimedia.Screenshot (screenshot)
import Scripts.System.Wallpaper (changeWallpaper)
import Scripts.Productivity.Clipboard (clipboardMenu, clipboardClear)

utilityKeys :: [(String, X ())]
utilityKeys =
    [ ("M-p",          screenshot)       -- Captura de pantalla
    , ("M-w",          changeWallpaper)  -- Cambiar a un fondo de Anime aleatorio
    , ("M-c",          clipboardMenu)    -- Historial del clipboard
    , ("M-S-c",        clipboardClear)   -- Limpiar historial del clipboard
    ]
