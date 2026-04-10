module Rules.Db (dbRules) where

import XMonad

import Variables (myWorkspaces)

dbRules :: [ManageHook]
dbRules =
    [ className =? "DBeaver"            --> doShift (myWorkspaces !! 3)
    ]
