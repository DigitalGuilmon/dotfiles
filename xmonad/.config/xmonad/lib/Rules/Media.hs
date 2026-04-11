module Rules.Media (mediaRules, mediaSpotifyHook) where

import XMonad

import Variables (wsMedia)

mediaRules :: [ManageHook]
mediaRules =
    [ className =? "Steam"              --> doShift wsMedia
    , className =? "Spotify"            --> doShift wsMedia
    ]

-- Hook separado para Spotify: se aplica vía dynamicPropertyChange en Rules.hs
-- porque Spotify (Electron) establece WM_CLASS después de mapear la ventana
mediaSpotifyHook :: ManageHook
mediaSpotifyHook = className =? "Spotify" --> doShift wsMedia
