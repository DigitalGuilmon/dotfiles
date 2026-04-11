module Rules.Web (webRules) where

import XMonad

import Variables (wsWeb)

webRules :: [ManageHook]
webRules =
    [ className =? "Brave-browser"      --> doShift wsWeb
    , className =? "firefox"            --> doShift wsWeb
    ]
