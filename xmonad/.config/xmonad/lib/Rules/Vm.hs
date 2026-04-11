module Rules.Vm (vmRules) where

import XMonad

import Variables (wsVm)

vmRules :: [ManageHook]
vmRules =
    [ className =? "VirtualBox Manager" --> doShift wsVm
    ]
