module Rules.Media (mediaRules, mediaSpotifyHook) where

import XMonad

import Variables (myWorkspaces)

mediaRules :: [ManageHook]
mediaRules =
    [ className =? "Steam"              --> doShift (myWorkspaces !! 6)
    , className =? "Spotify"            --> doShift (myWorkspaces !! 6)
    ]

-- Hook separado para Spotify: se aplica vía dynamicPropertyChange en Rules.hs
-- porque Spotify (Electron) establece WM_CLASS después de mapear la ventana
mediaSpotifyHook :: ManageHook
mediaSpotifyHook = className =? "Spotify" --> doShift (myWorkspaces !! 6)
