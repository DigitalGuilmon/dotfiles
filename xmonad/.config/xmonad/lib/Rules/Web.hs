module Rules.Web (webRules) where

import XMonad

import Variables (myWorkspaces)

webRules :: [ManageHook]
webRules =
    [ className =? "Brave-browser"      --> doShift (myWorkspaces !! 1)
    , className =? "firefox"            --> doShift (myWorkspaces !! 1)
    ]
