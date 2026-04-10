module Keys.Utilities where

import XMonad

import Scripts.Screenshot (screenshot)
import Scripts.Wallpaper (changeWallpaper)
import Scripts.Clipboard (clipboardMenu, clipboardClear)

utilityKeys :: [(String, X ())]
utilityKeys =
    [ ("M-p",          screenshot)       -- Captura de pantalla
    , ("M-w",          changeWallpaper)  -- Cambiar a un fondo de Anime aleatorio
    , ("M-c",          clipboardMenu)    -- Historial del clipboard
    , ("M-S-c",        clipboardClear)   -- Limpiar historial del clipboard
    ]
