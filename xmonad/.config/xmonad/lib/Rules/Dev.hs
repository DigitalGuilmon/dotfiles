module Rules.Dev (devRules) where

import XMonad

import Variables (wsDev)

devRules :: [ManageHook]
devRules =
    [ className =? "jetbrains-idea"     --> doShift wsDev
    , className =? "Code"               --> doShift wsDev
    ]
