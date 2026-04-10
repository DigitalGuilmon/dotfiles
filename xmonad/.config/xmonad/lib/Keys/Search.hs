module Keys.Search where

import XMonad

import Scripts.GridMenu (gridGoToWindow)
import Scripts.Prompts (searchGoogle, searchYouTube, searchMan, runShell)

searchKeys :: [(String, X ())]
searchKeys =
    [ ("M-g",          gridGoToWindow)  -- Lanzar Grid visual de ventanas
    , ("M-S-g",        searchGoogle)    -- Buscar en Google
    , ("M-S-y",        searchYouTube)   -- Buscar en YouTube
    , ("M-S-h",        searchMan)       -- Buscar manuales de terminal (Man Pages)
    , ("M-S-r",        runShell)        -- Ejecutar comando rápido (Shell Prompt)
    ]
