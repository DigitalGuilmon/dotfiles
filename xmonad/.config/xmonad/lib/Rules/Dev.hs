module Rules.Dev (devRules) where

import XMonad

import Variables (myWorkspaces)

devRules :: [ManageHook]
devRules =
    [ className =? "jetbrains-idea"     --> doShift (myWorkspaces !! 0)
    , className =? "Code"               --> doShift (myWorkspaces !! 0)
    ]
