module Rules.Vm (vmRules) where

import XMonad

import Variables (myWorkspaces)

vmRules :: [ManageHook]
vmRules =
    [ className =? "VirtualBox Manager" --> doShift (myWorkspaces !! 8)
    ]
