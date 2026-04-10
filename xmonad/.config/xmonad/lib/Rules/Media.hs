module Rules.Media (mediaRules) where

import XMonad

import Variables (myWorkspaces)

mediaRules :: [ManageHook]
mediaRules =
    [ className =? "Steam"              --> doShift (myWorkspaces !! 6)
    , className =? "Spotify"            --> doShift (myWorkspaces !! 6)
    ]
